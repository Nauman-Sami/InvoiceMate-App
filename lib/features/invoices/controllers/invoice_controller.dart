import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/local/local_database.dart';
import '../../../core/services/sync_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_constants.dart';

class InvoiceController extends GetxController {
  final AuthController _authCtrl = Get.find();
  final _uuid = const Uuid();

  final RxList<InvoiceModel> invoices = <InvoiceModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSyncing = false.obs;
  final Rx<String> filterStatus = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
  }

  String get userId => _authCtrl.userId!;

  void loadInvoices() {
    final all = LocalDatabase.getInvoicesForUser(userId);
    // Auto-update overdue
    for (final inv in all) {
      if (inv.isOverdue && inv.status == AppConstants.statusSent) {
        inv.status = AppConstants.statusOverdue;
        inv.save();
      }
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    invoices.assignAll(all);
  }

  List<InvoiceModel> get filteredInvoices {
    if (filterStatus.value == 'All') return invoices;
    return invoices.where((i) => i.status == filterStatus.value).toList();
  }

  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    LocalDatabase.saveInvoice(invoice);
    loadInvoices();
    _syncInBackground();
    return invoice;
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    invoice.syncStatus = AppConstants.syncPending;
    LocalDatabase.saveInvoice(invoice);
    loadInvoices();
    _syncInBackground();
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await SyncService.deleteInvoice(userId, invoiceId);
    loadInvoices();
  }

  Future<void> markAsPaid(String invoiceId, double amount) async {
    final inv = invoices.firstWhere((i) => i.id == invoiceId);
    inv.paidAmount = amount;
    inv.paidAt = DateTime.now();
    inv.status = amount >= inv.grandTotal
        ? AppConstants.statusPaid
        : AppConstants.statusSent;
    inv.syncStatus = AppConstants.syncPending;
    inv.save();
    loadInvoices();
    _syncInBackground();
  }

  Future<void> updateStatus(String invoiceId, String status) async {
    final inv = invoices.firstWhere((i) => i.id == invoiceId);
    inv.status = status;
    inv.syncStatus = AppConstants.syncPending;
    inv.save();
    loadInvoices();
    _syncInBackground();
  }

  Future<void> syncNow() async {
    isSyncing.value = true;
    await SyncService.syncToCloud(userId);
    await SyncService.syncFromCloud(userId);
    loadInvoices();
    isSyncing.value = false;
  }

  void _syncInBackground() async {
    await SyncService.syncToCloud(userId);
  }

  // Stats
  double get totalRevenue => invoices
      .where((i) => i.status == AppConstants.statusPaid)
      .fold(0, (sum, i) => sum + i.grandTotal);

  double get totalOutstanding => invoices
      .where((i) => i.status == AppConstants.statusSent ||
          i.status == AppConstants.statusOverdue)
      .fold(0, (sum, i) => sum + i.balanceDue);

  int get overdueCount =>
      invoices.where((i) => i.status == AppConstants.statusOverdue).length;

  int get draftCount =>
      invoices.where((i) => i.status == AppConstants.statusDraft).length;

  String generateInvoiceNumber() {
    final profile = LocalDatabase.getProfile(userId);
    final prefix = profile?.invoicePrefix ?? 'INV-';
    final counter = (profile?.invoiceCounter ?? 1);
    if (profile != null) {
      profile.invoiceCounter = counter + 1;
      profile.save();
    }
    return '$prefix${counter.toString().padLeft(4, '0')}';
  }

  String newId() => _uuid.v4();
}
