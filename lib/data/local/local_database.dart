import 'package:hive_flutter/hive_flutter.dart';
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/profile_model.dart';
import '../../core/constants/app_constants.dart';

class LocalDatabase {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ClientModelAdapter());
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(InvoiceItemAdapter());
    Hive.registerAdapter(InvoiceModelAdapter());
    Hive.registerAdapter(ProfileModelAdapter());

    // Open boxes
    await Hive.openBox<ClientModel>(AppConstants.clientBox);
    await Hive.openBox<ProductModel>(AppConstants.productBox);
    await Hive.openBox<InvoiceModel>(AppConstants.invoiceBox);
    await Hive.openBox<ProfileModel>(AppConstants.profileBox);
    await Hive.openBox(AppConstants.settingsBox);
  }

  static Box<ClientModel> get clients => Hive.box<ClientModel>(AppConstants.clientBox);
  static Box<ProductModel> get products => Hive.box<ProductModel>(AppConstants.productBox);
  static Box<InvoiceModel> get invoices => Hive.box<InvoiceModel>(AppConstants.invoiceBox);
  static Box<ProfileModel> get profile => Hive.box<ProfileModel>(AppConstants.profileBox);
  static Box get settings => Hive.box(AppConstants.settingsBox);

  // --- Client CRUD ---
  static void saveClient(ClientModel client) => clients.put(client.id, client);
  static void deleteClient(String id) => clients.delete(id);
  static List<ClientModel> getClientsForUser(String userId) =>
      clients.values.where((c) => c.userId == userId).toList();

  // --- Product CRUD ---
  static void saveProduct(ProductModel product) => products.put(product.id, product);
  static void deleteProduct(String id) => products.delete(id);
  static List<ProductModel> getProductsForUser(String userId) =>
      products.values.where((p) => p.userId == userId).toList();

  // --- Invoice CRUD ---
  static void saveInvoice(InvoiceModel invoice) => invoices.put(invoice.id, invoice);
  static void deleteInvoice(String id) => invoices.delete(id);
  static List<InvoiceModel> getInvoicesForUser(String userId) =>
      invoices.values.where((i) => i.userId == userId).toList();

  // --- Profile ---
  static ProfileModel? getProfile(String userId) => profile.get(userId);
  static void saveProfile(ProfileModel p) => profile.put(p.userId, p);

  // --- Pending Sync ---
  static List<ClientModel> getPendingClients(String userId) =>
      clients.values.where((c) => c.userId == userId && c.syncStatus == 'pending').toList();
  static List<ProductModel> getPendingProducts(String userId) =>
      products.values.where((p) => p.userId == userId && p.syncStatus == 'pending').toList();
  static List<InvoiceModel> getPendingInvoices(String userId) =>
      invoices.values.where((i) => i.userId == userId && i.syncStatus == 'pending').toList();
}
