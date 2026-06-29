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
