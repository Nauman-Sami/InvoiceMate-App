import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';

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
      allowedExtensions: ['csv', 'xlsx', 'xls'],
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
    return _parseExcel(bytes);
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
