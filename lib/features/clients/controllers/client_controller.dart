import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/client_model.dart';
import '../../../data/local/local_database.dart';
import '../../../core/services/sync_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_constants.dart';

class ClientController extends GetxController {
  final AuthController _authCtrl = Get.find();
  final _uuid = const Uuid();

  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  String get userId => _authCtrl.userId!;

  void loadClients() {
    final all = LocalDatabase.getClientsForUser(userId);
    all.sort((a, b) => a.name.compareTo(b.name));
    clients.assignAll(all);
  }

  Future<ClientModel> addClient({
    required String name,
    required String email,
    required String phone,
    required String address,
    String? companyName,
    String? taxNumber,
  }) async {
    final client = ClientModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      companyName: companyName,
      taxNumber: taxNumber,
      createdAt: DateTime.now(),
      syncStatus: AppConstants.syncPending,
      userId: userId,
    );
    LocalDatabase.saveClient(client);
    loadClients();
    SyncService.syncToCloud(userId);
    return client;
  }

  /// Bulk-import clients from a mapped spreadsheet. Each map may contain the
  /// keys: name, email, phone, address, company, tax. Duplicate names are
  /// skipped. Returns how many were added.
  Future<int> importClients(List<Map<String, String>> rows) async {
    final existing = clients.map((c) => c.name.trim().toLowerCase()).toSet();
    int added = 0;
    for (final r in rows) {
      final name = (r['name'] ?? '').trim();
      if (name.isEmpty) continue;
      if (existing.contains(name.toLowerCase())) continue;
      existing.add(name.toLowerCase());
      final company = (r['company'] ?? '').trim();
      final tax = (r['tax'] ?? '').trim();
      final client = ClientModel(
        id: _uuid.v4(),
        name: name,
        email: (r['email'] ?? '').trim(),
        phone: (r['phone'] ?? '').trim(),
        address: (r['address'] ?? '').trim(),
        companyName: company.isEmpty ? null : company,
        taxNumber: tax.isEmpty ? null : tax,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );
      LocalDatabase.saveClient(client);
      added++;
    }
    loadClients();
    SyncService.syncToCloud(userId);
    return added;
  }

  Future<void> updateClient(ClientModel client) async {
    client.syncStatus = AppConstants.syncPending;
    LocalDatabase.saveClient(client);
    loadClients();
    SyncService.syncToCloud(userId);
  }

  Future<void> deleteClient(String clientId) async {
    await SyncService.deleteClient(userId, clientId);
    loadClients();
  }

  ClientModel? getClientById(String id) {
    try {
      return clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
