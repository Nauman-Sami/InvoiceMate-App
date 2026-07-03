import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/count_header.dart';
import '../controllers/invoice_controller.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  static const List<String> _filters = ['All', 'Draft', 'Sent', 'Paid', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<InvoiceController>();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed('/invoices/create'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _filters.map((f) {
                final isSelected = ctrl.filterStatus.value == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (_) => ctrl.filterStatus.value = f,
                    selectedColor: AppTheme.primary.withOpacity(0.15),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
          )),
        ),
      ),
      body: Obx(() {
        final list = ctrl.filteredInvoices;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('No invoices', style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/invoices/create'),
                  child: const Text('Create Invoice'),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            CountHeader(label: 'Total Invoices', count: ctrl.invoices.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final inv = list[i];
                  final statusColor = AppTheme.getStatusColor(inv.status);
                  return Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => _confirmDelete(ctrl, inv.id),
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => Get.toNamed('/invoices/detail', arguments: inv),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primary)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inv.clientName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(inv.invoiceNumber,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${inv.currency} ${fmt.format(inv.grandTotal)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(inv.status,
                                    style: TextStyle(
                                        fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: AppTheme.divider, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('Due: ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const Spacer(),
                          if (inv.syncStatus == 'pending')
                            Row(
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 13, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text('Pending sync', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Icon(Icons.cloud_done_outlined, size: 13, color: AppTheme.accent),
                                const SizedBox(width: 4),
                                Text('Synced', style: TextStyle(fontSize: 11, color: AppTheme.accent)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/invoices/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(InvoiceController ctrl, String id) {
    Get.defaultDialog(
      title: 'Delete Invoice',
      middleText: 'Are you sure you want to delete this invoice?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.danger,
      onConfirm: () {
        ctrl.deleteInvoice(id);
        Get.back();
      },
    );
  }
}
