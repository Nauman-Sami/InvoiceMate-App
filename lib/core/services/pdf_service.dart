import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/client_model.dart';
import '../../data/models/product_model.dart';

class PdfService {
  static final _fmt = NumberFormat('#,##0.00', 'en_US');

  // Cached logo so we only decode the asset once.
  static pw.MemoryImage? _logo;
  static Future<pw.MemoryImage> _loadLogo() async {
    if (_logo != null) return _logo!;
    final bytes = await rootBundle.load('assets/splash/splash.png');
    _logo = pw.MemoryImage(bytes.buffer.asUint8List());
    return _logo!;
  }

  // Faint centered logo painted behind every page.
  static pw.Widget _watermark(pw.MemoryImage logo) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Opacity(
          opacity: 0.06,
          child: pw.Image(logo, width: 320),
        ),
      ),
    );
  }

  static pw.Widget _brandingFooter(PdfColor primaryColor, PdfColor textGray) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColor.fromHex('E2E8F0')),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text('© Copyrights Reserved  •  Designed by Nauman Sami',
                  style: pw.TextStyle(color: textGray, fontSize: 8)),
              pw.SizedBox(height: 2),
              pw.Text('Contact # 0318-6606262',
                  style: pw.TextStyle(color: textGray, fontSize: 8)),
            ],
          ),
        ),
      ],
    );
  }

  static Future<File> generateInvoicePdf(
      InvoiceModel invoice, ProfileModel? profile) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    final primaryColor = PdfColor.fromHex('2563EB');
    final lightGray = PdfColor.fromHex('F8FAFC');
    final textGray = PdfColor.fromHex('64748B');
    final textDark = PdfColor.fromHex('1E293B');
    final dividerColor = PdfColor.fromHex('E2E8F0');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          buildBackground: (context) => _watermark(logo),
        ),
        build: (context) => [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        profile?.businessName ?? 'InvoiceMate',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (profile?.address != null)
                      pw.Text(profile!.address, style: pw.TextStyle(color: textGray, fontSize: 10)),
                    if (profile?.phone != null)
                      pw.Text(profile!.phone, style: pw.TextStyle(color: textGray, fontSize: 10)),
                    if (profile?.email != null)
                      pw.Text(profile!.email, style: pw.TextStyle(color: textGray, fontSize: 10)),
                    if (profile?.taxNumber != null)
                      pw.Text('Tax No: ${profile!.taxNumber}',
                          style: pw.TextStyle(color: textGray, fontSize: 10)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INVOICE',
                      style: pw.TextStyle(
                          fontSize: 28, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.invoiceNumber,
                      style: pw.TextStyle(fontSize: 14, color: textGray)),
                  pw.SizedBox(height: 8),
                  pw.Text(
                      'Issue: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}',
                      style: pw.TextStyle(fontSize: 10, color: textGray)),
                  pw.Text(
                      'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                      style: pw.TextStyle(fontSize: 10, color: textGray)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: invoice.status == 'Paid'
                          ? PdfColor.fromHex('10B981')
                          : invoice.status == 'Overdue'
                              ? PdfColor.fromHex('EF4444')
                              : primaryColor,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(invoice.status.toUpperCase(),
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 32),
          // Bill To
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold, color: textGray,
                        letterSpacing: 1)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.clientName,
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textDark)),
                if (invoice.clientEmail.isNotEmpty)
                  pw.Text(invoice.clientEmail, style: pw.TextStyle(color: textGray, fontSize: 10)),
                if (invoice.clientAddress.isNotEmpty)
                  pw.Text(invoice.clientAddress, style: pw.TextStyle(color: textGray, fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          // Items table
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FixedColumnWidth(60),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(60),
              4: const pw.FixedColumnWidth(90),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: ['DESCRIPTION', 'QTY', 'UNIT PRICE', 'TAX', 'TOTAL']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  color: PdfColors.white, fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
              ),
              // Items
              ...invoice.items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('F8FAFC');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.productName,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          if (item.description.isNotEmpty)
                            pw.Text(item.description,
                                style: pw.TextStyle(color: textGray, fontSize: 9)),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: pw.Text('${item.quantity} ${item.unit}',
                          style: pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: pw.Text('${invoice.currency} ${_fmt.format(item.unitPrice)}',
                          style: pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: pw.Text('${item.taxPercent}%',
                          style: pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: pw.Text('${invoice.currency} ${_fmt.format(item.total)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 16),
          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 240,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', '${invoice.currency} ${_fmt.format(invoice.subtotal)}', textGray),
                    if (invoice.totalTax > 0)
                      _totalRow('Tax', '${invoice.currency} ${_fmt.format(invoice.totalTax)}', textGray),
                    if (invoice.discountPercent > 0)
                      _totalRow('Discount (${invoice.discountPercent}%)',
                          '-${invoice.currency} ${_fmt.format(invoice.discountAmount)}', textGray),
                    pw.Divider(color: dividerColor),
                    _totalRow(
                      'TOTAL',
                      '${invoice.currency} ${_fmt.format(invoice.grandTotal)}',
                      primaryColor,
                      bold: true,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Notes
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('NOTES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textGray)),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.notes!, style: pw.TextStyle(fontSize: 10, color: textGray)),
                ],
              ),
            ),
          ],
          // Bank Details
          if (profile?.bankDetails != null && profile!.bankDetails!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BANK DETAILS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textGray)),
                  pw.SizedBox(height: 4),
                  pw.Text(profile!.bankDetails!, style: pw.TextStyle(fontSize: 10, color: textGray)),
                ],
              ),
            ),
          ],
          // Signature
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 150, height: 1, color: dividerColor),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signature',
                      style: pw.TextStyle(fontSize: 9, color: textGray)),
                ],
              ),
            ],
          ),
          // Footer
          pw.SizedBox(height: 32),
          pw.Divider(color: dividerColor),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(color: primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  '© Copyrights Reserved  •  Designed by Nauman Sami',
                  style: pw.TextStyle(color: textGray, fontSize: 8),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Contact # 0318-6606262',
                  style: pw.TextStyle(color: textGray, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _totalRow(String label, String value, PdfColor color,
      {bool bold = false, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  color: color, fontSize: fontSize,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  color: color, fontSize: fontSize,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static Future<void> sharePdf(InvoiceModel invoice, ProfileModel? profile) async {
    final file = await generateInvoicePdf(invoice, profile);
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Invoice ${invoice.invoiceNumber} from ${profile?.businessName ?? 'InvoiceMate'}');
  }

  static Future<void> printPdf(InvoiceModel invoice, ProfileModel? profile) async {
    final file = await generateInvoicePdf(invoice, profile);
    await Printing.layoutPdf(onLayout: (_) async => file.readAsBytesSync());
  }

  // ---------------------------------------------------------------------------
  // Clients & Products list exports
  // ---------------------------------------------------------------------------

  static final _primary = PdfColor.fromHex('2563EB');
  static final _textGray = PdfColor.fromHex('64748B');
  static final _textDark = PdfColor.fromHex('1E293B');

  static pw.Widget _listHeader(pw.MemoryImage logo, String title, int count) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 38,
          height: 38,
          child: pw.Image(logo),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('InvoiceMate',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
              pw.Text('$title  ($count)',
                  style: pw.TextStyle(fontSize: 11, color: _textGray)),
            ],
          ),
        ),
        pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
            style: pw.TextStyle(fontSize: 10, color: _textGray)),
      ],
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> cells) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: _primary),
      children: cells
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: pw.Text(h,
                    style: pw.TextStyle(
                        color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  static pw.Padding _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9,
                color: _textDark,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  static Future<File> generateClientsPdf(List<ClientModel> clients) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        buildBackground: (context) => _watermark(logo),
      ),
      build: (context) => [
        _listHeader(logo, 'Clients', clients.length),
        pw.SizedBox(height: 18),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0')),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(3.5),
            3: const pw.FlexColumnWidth(2.5),
          },
          children: [
            _tableHeaderRow(['NAME', 'COMPANY', 'EMAIL', 'PHONE']),
            ...clients.map((c) => pw.TableRow(children: [
                  _cell(c.name, bold: true),
                  _cell(c.companyName ?? '-'),
                  _cell(c.email.isEmpty ? '-' : c.email),
                  _cell(c.phone.isEmpty ? '-' : c.phone),
                ])),
          ],
        ),
        pw.SizedBox(height: 28),
        _brandingFooter(_primary, _textGray),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/InvoiceMate-Clients.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateProductsPdf(List<ProductModel> products) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        buildBackground: (context) => _watermark(logo),
      ),
      build: (context) => [
        _listHeader(logo, 'Products & Services', products.length),
        pw.SizedBox(height: 18),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0')),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(4),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            _tableHeaderRow(['NAME', 'DESCRIPTION', 'UNIT', 'PRICE', 'TAX']),
            ...products.map((p) => pw.TableRow(children: [
                  _cell(p.name, bold: true),
                  _cell(p.description.isEmpty ? '-' : p.description),
                  _cell(p.unit),
                  _cell(_fmt.format(p.price)),
                  _cell('${p.taxPercent}%'),
                ])),
          ],
        ),
        pw.SizedBox(height: 28),
        _brandingFooter(_primary, _textGray),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/InvoiceMate-Products.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> shareClientsPdf(List<ClientModel> clients) async {
    final file = await generateClientsPdf(clients);
    await Share.shareXFiles([XFile(file.path)], subject: 'InvoiceMate — Clients list');
  }

  static Future<void> printClientsPdf(List<ClientModel> clients) async {
    final file = await generateClientsPdf(clients);
    await Printing.layoutPdf(onLayout: (_) async => file.readAsBytesSync());
  }

  static Future<void> shareProductsPdf(List<ProductModel> products) async {
    final file = await generateProductsPdf(products);
    await Share.shareXFiles([XFile(file.path)], subject: 'InvoiceMate — Products list');
  }

  static Future<void> printProductsPdf(List<ProductModel> products) async {
    final file = await generateProductsPdf(products);
    await Printing.layoutPdf(onLayout: (_) async => file.readAsBytesSync());
  }
}
