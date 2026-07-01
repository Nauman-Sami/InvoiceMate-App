import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// A parsed spreadsheet: the header names + the data rows (as strings).
class ParsedTable {
  final List<String> headers;
  final List<List<String>> rows;
  const ParsedTable(this.headers, this.rows);

  bool get isEmpty => headers.isEmpty || rows.isEmpty;
}

class ImportService {
  /// Lets the user pick a .csv / .xlsx / .xls file and parses it into a table.
  /// Returns null if the user cancels. Throws on an unreadable file.
  static Future<ParsedTable?> pickAndParse() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls', 'pdf'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return null;
    final file = res.files.first;
    final bytes = file.bytes;
    if (bytes == null) throw 'Could not read the file.';
    final name = (file.name).toLowerCase();

    if (name.endsWith('.csv')) {
      return _parseCsv(utf8.decode(bytes, allowMalformed: true));
    }
    if (name.endsWith('.pdf')) {
      return _parsePdf(bytes);
    }
    return _parseExcel(bytes);
  }

  /// Extracts a product/price table from a PDF (e.g. a pharmacy product list).
  /// Each data row is expected to be: [row#] name  $amount1  $amount2  ...
  /// The amounts become columns (Sale / Wholesale / Purchase). Because PDFs
  /// merge name+code+unit, the "Product" column may contain the unit too.
  static ParsedTable _parsePdf(List<int> bytes) {
    final doc = sf.PdfDocument(inputBytes: Uint8List.fromList(bytes));
    String text;
    try {
      text = sf.PdfTextExtractor(doc).extractText();
    } finally {
      doc.dispose();
    }

    // First pass requires a "$" before each amount (avoids misreading dosages
    // like "0.25mg" as prices). If that finds nothing, fall back to a looser
    // match for PDFs that print amounts without a currency symbol.
    var result = _extractPdfRows(text, requireDollar: true);
    if (result.$1.isEmpty) {
      result = _extractPdfRows(text, requireDollar: false);
    }
    final rows = result.$1;
    final maxAmts = result.$2;

    if (rows.isEmpty) {
      throw 'No product rows were found in this PDF. If it is not a product/price '
          'list, please export it as CSV or Excel instead.';
    }

    final headers = <String>['No', 'Product'];
    const amtNames = ['Sale Rate', 'Wholesale Rate', 'Purchase Rate'];
    for (var i = 0; i < maxAmts; i++) {
      headers.add(i < amtNames.length ? amtNames[i] : 'Amount ${i + 1}');
    }
    final width = headers.length;
    final padded = rows
        .map((r) => List<String>.generate(width, (j) => j < r.length ? r[j] : ''))
        .toList();
    return ParsedTable(headers, padded);
  }

  static ParsedTable _parseCsv(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final table = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(normalized);
    return _fromMatrix(table.map((r) => r.map((c) => c?.toString() ?? '').toList()).toList());
  }

  static ParsedTable _parseExcel(List<int> bytes) {
    final excel = xls.Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return const ParsedTable([], []);
    final sheet = excel.tables[excel.tables.keys.first]!;
    final matrix = <List<String>>[];
    for (final row in sheet.rows) {
      matrix.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
    }
    return _fromMatrix(matrix);
  }

  /// Takes a raw matrix, finds the first non-empty row as the header,
  /// and normalizes every data row to the header's width.
  static ParsedTable _fromMatrix(List<List<String>> matrix) {
    // drop fully-empty leading rows
    int headerIdx = 0;
    while (headerIdx < matrix.length &&
        matrix[headerIdx].every((c) => c.trim().isEmpty)) {
      headerIdx++;
    }
    if (headerIdx >= matrix.length) return const ParsedTable([], []);

    final headers = matrix[headerIdx].map((h) => h.trim()).toList();
    final width = headers.length;
    final rows = <List<String>>[];
    for (var i = headerIdx + 1; i < matrix.length; i++) {
      final raw = matrix[i];
      if (raw.every((c) => c.trim().isEmpty)) continue;
      final row = List<String>.generate(
          width, (j) => j < raw.length ? raw[j].trim() : '');
      rows.add(row);
    }
    return ParsedTable(headers, rows);
  }

  /// Scans PDF text line-by-line for "name  $a  $b ..." rows.
  /// Returns (rows, maxAmountColumns). Each row is [seq, name, amt1, amt2 ...].
  static (List<List<String>>, int) _extractPdfRows(String text,
      {required bool requireDollar}) {
    final moneyRe = requireDollar
        ? RegExp(r'\$\s*([0-9][0-9,]*\.[0-9]{2})')
        : RegExp(r'([0-9][0-9,]*\.[0-9]{2})');
    final firstMoneyRe = requireDollar
        ? RegExp(r'\$\s*[0-9][0-9,]*\.[0-9]{2}')
        : RegExp(r'[0-9][0-9,]*\.[0-9]{2}');

    final rows = <List<String>>[];
    int maxAmts = 0;
    int seq = 0;

    for (final raw in text.split('\n')) {
      var line = raw.trim();
      if (line.isEmpty) continue;
      final amts =
          moneyRe.allMatches(line).map((m) => m.group(1)!.replaceAll(',', '')).toList();
      if (amts.isEmpty) continue; // headers, page titles, etc.

      seq++;
      // Strip a leading sequential row number if the software printed one.
      final numStr = seq.toString();
      if (line.startsWith(numStr)) line = line.substring(numStr.length);

      // Product name = everything before the first money amount.
      final firstIdx = line.indexOf(firstMoneyRe);
      var pname = firstIdx > 0 ? line.substring(0, firstIdx) : line;
      pname = pname.replaceAll(r'$', '').trim();
      if (pname.isEmpty) continue;

      if (amts.length > maxAmts) maxAmts = amts.length;
      rows.add(<String>[seq.toString(), pname, ...amts]);
    }
    return (rows, maxAmts);
  }

  /// Best-guess a header index for a target field, using priority keywords.
  /// Returns -1 if nothing matches. [taken] holds already-assigned indices.
  static int guessColumn(List<String> headers, List<String> keywords,
      {List<String> avoid = const [], Set<int> taken = const {}}) {
    final lower = headers.map((h) => h.toLowerCase()).toList();
    // Prefer earlier keywords (higher priority).
    for (final kw in keywords) {
      for (var i = 0; i < lower.length; i++) {
        if (taken.contains(i)) continue;
        if (avoid.any((a) => lower[i].contains(a))) continue;
        if (lower[i].contains(kw)) return i;
      }
    }
    return -1;
  }

  /// Parse a currency/number string like "$ 1,465.00" into a double.
  static double parseNumber(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
