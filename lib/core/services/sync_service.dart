import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/local/local_database.dart';
import '../../data/models/client_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/invoice_model.dart';
import '../../core/constants/app_constants.dart';

class SyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Sync all pending local data to Firestore
  static Future<void> syncToCloud(String userId) async {
    if (!await isOnline()) return;

    await _syncClients(userId);
    await _syncProducts(userId);
    await _syncInvoices(userId);
  }

  /// Pull latest data from Firestore to local
  static Future<void> syncFromCloud(String userId) async {
    if (!await isOnline()) return;

    await _pullClients(userId);
    await _pullProducts(userId);
    await _pullInvoices(userId);
  }

  static Future<void> _syncClients(String userId) async {
    final pending = LocalDatabase.getPendingClients(userId);
    for (final client in pending) {
      try {
        await _db
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.clientsCollection)
            .doc(client.id)
            .set(client.toFirestore());
        client.syncStatus = 'synced';
        client.save();
      } catch (_) {}
    }
  }

  static Future<void> _syncProducts(String userId) async {
    final pending = LocalDatabase.getPendingProducts(userId);
    for (final product in pending) {
      try {
        await _db
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.productsCollection)
            .doc(product.id)
            .set(product.toFirestore());
        product.syncStatus = 'synced';
        product.save();
      } catch (_) {}
    }
  }

  static Future<void> _syncInvoices(String userId) async {
    final pending = LocalDatabase.getPendingInvoices(userId);
    for (final invoice in pending) {
      try {
        await _db
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.invoicesCollection)
            .doc(invoice.id)
            .set(invoice.toFirestore());
        invoice.syncStatus = 'synced';
        invoice.save();
      } catch (_) {}
    }
  }

  static Future<void> _pullClients(String userId) async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.clientsCollection)
        .get();
    for (final doc in snap.docs) {
      final client = ClientModel.fromFirestore(doc.data());
      LocalDatabase.saveClient(client);
    }
  }

  static Future<void> _pullProducts(String userId) async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.productsCollection)
        .get();
    for (final doc in snap.docs) {
      final product = ProductModel.fromFirestore(doc.data());
      LocalDatabase.saveProduct(product);
    }
  }

  static Future<void> _pullInvoices(String userId) async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.invoicesCollection)
        .get();
    for (final doc in snap.docs) {
      final invoice = InvoiceModel.fromFirestore(doc.data());
      LocalDatabase.saveInvoice(invoice);
    }
  }

  /// Delete from both local and Firestore
  static Future<void> deleteInvoice(String userId, String invoiceId) async {
    LocalDatabase.deleteInvoice(invoiceId);
    if (await isOnline()) {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.invoicesCollection)
          .doc(invoiceId)
          .delete();
    }
  }

  static Future<void> deleteClient(String userId, String clientId) async {
    LocalDatabase.deleteClient(clientId);
    if (await isOnline()) {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.clientsCollection)
          .doc(clientId)
          .delete();
    }
  }

  static Future<void> deleteProduct(String userId, String productId) async {
    LocalDatabase.deleteProduct(productId);
    if (await isOnline()) {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .delete();
    }
  }
}
