import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/pdf_service.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/local/local_database.dart';
import '../controllers/invoice_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoice = Get.arguments as InvoiceModel;
    final ctrl = Get.find<InvoiceController>();
    final auth = Get.find<AuthController>();
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final profile = LocalDatabase.getProfile(auth.userId!);
    final sortedItems = [...invoice.items]
      ..sort((a, b) =>
          a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));

    final statusColor = AppTheme.getStatusColor(invoice.status);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Get.toNamed('/invoices/create', arguments: invoice),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'share') await PdfService.sharePdf(invoice, profile);
              if (v == 'print') await PdfService.printPdf(invoice, profile);
              if (v == 'delete') {
                Get.defaultDialog(
                  title: 'Delete',
                  middleText: 'Delete this invoice?',
                  textConfirm: 'Delete',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  buttonColor: AppTheme.danger,
                  onConfirm: () {
                    ctrl.deleteInvoice(invoice.id);
                    Get.until((r) => r.settings.name == '/invoices');
                  },
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Share PDF'), dense: true)),
              const PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print_outlined), title: Text('Print'), dense: true)),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: AppTheme.danger), title: Text('Delete', style: TextStyle(color: AppTheme.danger)), dense: true)),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + Amount card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(invoice.clientName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(invoice.status,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('${invoice.currency} ${fmt.format(invoice.grandTotal)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Due ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(child: _ActionBtn(
                  icon: Icons.share_outlined,
                  label: 'Share PDF',
                  onTap: () => PdfService.sharePdf(invoice, profile),
                )),
                const SizedBox(width: 10),
                Expanded(child: _ActionBtn(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  onTap: () => PdfService.printPdf(invoice, profile),
                )),
                const SizedBox(width: 10),
                if (invoice.status != 'Paid')
                  Expanded(child: _ActionBtn(
                    icon: Icons.check_circle_outline,
                    label: 'Mark Paid',
                    color: AppTheme.accent,
                    onTap: () => _markPaid(ctrl, invoice),
                  )),
              ],
            ),
            const SizedBox(height: 16),
            // Status change
            if (invoice.status != 'Paid' && invoice.status != 'Cancelled')
              _Card(
                title: 'Update Status',
                child: Wrap(
                  spacing: 8,
                  children: ['Draft', 'Sent', 'Overdue', 'Cancelled'].map((s) {
                    final color = AppTheme.getStatusColor(s);
                    return ActionChip(
                      label: Text(s),
                      backgroundColor: invoice.status == s
                          ? color.withOpacity(0.15)
                          : null,
                      labelStyle: TextStyle(
                          color: invoice.status == s ? color : AppTheme.textSecondary),
                      onPressed: () => ctrl.updateStatus(invoice.id, s),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 8),
            // Invoice info
            _Card(
              title: 'Invoice Details',
              child: Column(
                children: [
                  _InfoRow('Invoice #', invoice.invoiceNumber),
                  _InfoRow('Issue Date', DateFormat('dd MMM yyyy').format(invoice.issueDate)),
                  _InfoRow('Due Date', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
                  _InfoRow('Currency', invoice.currency),
                  if (invoice.notes != null && invoice.notes!.isNotEmpty)
                    _InfoRow('Notes', invoice.notes!),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Client info
            _Card(
              title: 'Client',
              child: Column(
                children: [
                  _InfoRow('Name', invoice.clientName),
                  _InfoRow('Email', invoice.clientEmail),
                  if (invoice.clientAddress.isNotEmpty)
                    _InfoRow('Address', invoice.clientAddress),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Items
            _Card(
              title: 'Items (${invoice.items.length})',
              child: Column(
                children: [
                  ...sortedItems.asMap().entries.map((e) {
                    final item = e.value;
                    return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${e.key + 1}. ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                            Expanded(child: Text(item.productName,
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                            Text('${invoice.currency} ${fmt.format(item.total)}',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('${item.quantity} ${item.unit} × ${invoice.currency} ${fmt.format(item.unitPrice)}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            if (item.taxPercent > 0)
                              Text(' + ${item.taxPercent}% tax',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  );
                  }),
                  const Divider(),
                  _InfoRow('Subtotal', '${invoice.currency} ${fmt.format(invoice.subtotal)}'),
                  if (invoice.totalTax > 0)
                    _InfoRow('Tax', '${invoice.currency} ${fmt.format(invoice.totalTax)}'),
                  if (invoice.discountPercent > 0)
                    _InfoRow('Discount (${invoice.discountPercent}%)',
                        '-${invoice.currency} ${fmt.format(invoice.discountAmount)}'),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${invoice.currency} ${fmt.format(invoice.grandTotal)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markPaid(InvoiceController ctrl, InvoiceModel invoice) {
    final amtCtrl = TextEditingController(text: invoice.grandTotal.toString());
    Get.defaultDialog(
      title: 'Mark as Paid',
      content: Column(
        children: [
          Text('Amount paid (${invoice.currency}):'),
          const SizedBox(height: 8),
          TextField(
            controller: amtCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      textConfirm: 'Confirm',
      textCancel: 'Cancel',
      onConfirm: () {
        ctrl.markAsPaid(invoice.id, double.tryParse(amtCtrl.text) ?? invoice.grandTotal);
        Get.back();
        Get.snackbar('Paid!', 'Invoice marked as paid', backgroundColor: AppTheme.accent, colorText: Colors.white);
      },
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionBtn({required this.icon, required this.label, required this.onTap,
      this.color = AppTheme.primary});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
