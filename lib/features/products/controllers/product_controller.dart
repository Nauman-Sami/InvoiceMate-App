import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/product_model.dart';
import '../../../data/local/local_database.dart';
import '../../../core/services/sync_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_constants.dart';

class ProductController extends GetxController {
  final AuthController _authCtrl = Get.find();
  final _uuid = const Uuid();

  final RxList<ProductModel> products = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  String get userId => _authCtrl.userId!;

  void loadProducts() {
    final all = LocalDatabase.getProductsForUser(userId);
    all.sort((a, b) => a.name.compareTo(b.name));
    products.assignAll(all);
  }

  Future<ProductModel> addProduct({
    required String name,
    required String description,
    required double price,
    double taxPercent = 0,
    String unit = 'pcs',
    String? sku,
    double? wholesalePrice,
  }) async {
    final product = ProductModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      price: price,
      taxPercent: taxPercent,
      unit: unit,
      sku: sku,
      createdAt: DateTime.now(),
      syncStatus: AppConstants.syncPending,
      userId: userId,
      wholesalePrice: wholesalePrice,
    );
    LocalDatabase.saveProduct(product);
    loadProducts();
    SyncService.syncToCloud(userId);
    return product;
  }

  /// Bulk-import products from a mapped spreadsheet. Each map may contain the
  /// keys: name, description, price, wholesale, tax, unit, code. Duplicate
  /// names (already in the catalog) are skipped. Returns how many were added.
  Future<int> importProducts(List<Map<String, String>> rows) async {
    final existing = products.map((p) => p.name.trim().toLowerCase()).toSet();
    int added = 0;
    for (final r in rows) {
      final name = (r['name'] ?? '').trim();
      if (name.isEmpty) continue;
      if (existing.contains(name.toLowerCase())) continue;
      existing.add(name.toLowerCase());
      final unit = (r['unit'] ?? '').trim();
      final code = (r['code'] ?? '').trim();
      final ws = (r['wholesale'] ?? '').trim();
      final product = ProductModel(
        id: _uuid.v4(),
        name: name,
        description: (r['description'] ?? '').trim(),
        price: double.tryParse(r['price'] ?? '') ?? 0,
        taxPercent: double.tryParse(r['tax'] ?? '') ?? 0,
        unit: unit.isEmpty ? 'pcs' : unit,
        sku: code.isEmpty ? null : code,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
        wholesalePrice: ws.isEmpty ? null : double.tryParse(ws),
      );
      LocalDatabase.saveProduct(product);
      added++;
    }
    loadProducts();
    SyncService.syncToCloud(userId);
    return added;
  }

  Future<void> updateProduct(ProductModel product) async {
    product.syncStatus = AppConstants.syncPending;
    LocalDatabase.saveProduct(product);
    loadProducts();
    SyncService.syncToCloud(userId);
  }

  Future<void> deleteProduct(String productId) async {
    await SyncService.deleteProduct(userId, productId);
    loadProducts();
  }

  ProductModel? getById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
