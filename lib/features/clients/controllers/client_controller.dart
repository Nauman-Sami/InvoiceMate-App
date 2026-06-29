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
