import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../invoices/controllers/invoice_controller.dart';
import '../../clients/controllers/client_controller.dart';
import '../../products/controllers/product_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final invoiceCtrl = Get.find<InvoiceController>();
    final currency = 'PKR';
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF1FF),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('InvoiceMate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Obx(() => Text(
              'Hi, ${auth.userName?.split(' ').first ?? 'there'}!',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w400),
            )),
          ],
        ),
        actions: [
          Obx(() => invoiceCtrl.isSyncing.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.sync_rounded),
                  tooltip: 'Sync now',
                  onPressed: invoiceCtrl.syncNow,
                )),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Get.toNamed('/profile'),
          ),
        ],
      ),
      body: AppBackground(child: Obx(() {
        final invoices = invoiceCtrl.invoices;
        return RefreshIndicator(
          onRefresh: invoiceCtrl.syncNow,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                FadeInDown(
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(
                        label: 'Total Revenue',
                        value: '$currency ${fmt.format(invoiceCtrl.totalRevenue)}',
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.accent,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        label: 'Outstanding',
                        value: '$currency ${fmt.format(invoiceCtrl.totalOutstanding)}',
                        icon: Icons.hourglass_empty_rounded,
                        color: AppTheme.warning,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(
                        label: 'Overdue',
                        value: '${invoiceCtrl.overdueCount} invoices',
                        icon: Icons.warning_amber_rounded,
                        color: AppTheme.danger,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        label: 'Total Invoices',
                        value: '${invoices.length}',
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.primary,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Today's sales
                FadeInDown(
                  delay: const Duration(milliseconds: 150),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.today_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Sales  •  ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                            ),
                            const SizedBox(height: 3),
                            Text('$currency ${fmt.format(invoiceCtrl.todaysSales)}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Daily Sales breakdown
                Builder(builder: (_) {
                  final days = invoiceCtrl.salesByDay.take(7).toList();
                  if (days.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Sales',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          children: [
                            for (var k = 0; k < days.length; k++) ...[
                              if (k > 0) const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 14, color: AppTheme.textSecondary),
                                    const SizedBox(width: 10),
                                    Text(DateFormat('dd MMM yyyy').format(days[k].key),
                                        style: const TextStyle(fontSize: 13)),
                                    const Spacer(),
                                    Text('$currency ${fmt.format(days[k].value)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                // Quick Actions
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: const Text('Quick Actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      Expanded(child: _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'New Invoice',
                        color: AppTheme.primary,
                        onTap: () => Get.toNamed('/invoices/create'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickAction(
                        icon: Icons.people_outline_rounded,
                        label: 'Clients',
                        color: AppTheme.accent,
                        onTap: () => Get.toNamed('/clients'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickAction(
                        icon: Icons.inventory_2_outlined,
                        label: 'Products',
                        color: AppTheme.warning,
                        onTap: () => Get.toNamed('/products'),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Recent Invoices
                FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Invoices',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      TextButton(
                        onPressed: () => Get.toNamed('/invoices'),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (invoices.isEmpty)
                  FadeIn(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No invoices yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => Get.toNamed('/invoices/create'),
                              child: const Text('Create First Invoice'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...invoices.take(5).toList().asMap().entries.map((entry) {
                    final inv = entry.value;
                    return FadeInUp(
                      delay: Duration(milliseconds: 300 + entry.key * 50),
                      child: _InvoiceListTile(invoice: inv, currency: currency, fmt: fmt),
                    );
                  }),
              ],
            ),
          ),
        );
      })),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/invoices/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _InvoiceListTile extends StatelessWidget {
  final dynamic invoice;
  final String currency;
  final NumberFormat fmt;
  const _InvoiceListTile({required this.invoice, required this.currency, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(invoice.status);
    return InkWell(
      onTap: () => Get.toNamed('/invoices/detail', arguments: invoice),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.clientName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(invoice.invoiceNumber, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$currency ${fmt.format(invoice.grandTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(invoice.status,
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
