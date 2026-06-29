import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 2)
class ProductModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  double price;

  @HiveField(4)
  double taxPercent; // e.g. 18 for 18%

  @HiveField(5)
  String unit; // e.g. 'pcs', 'kg', 'hr', 'service'

  @HiveField(6)
  String? sku;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String syncStatus;

  @HiveField(9)
  String userId;

  @HiveField(10)
  double? wholesalePrice; // optional wholesale rate

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.taxPercent = 0,
    this.unit = 'pcs',
    this.sku,
    required this.createdAt,
    this.syncStatus = 'pending',
    required this.userId,
    this.wholesalePrice,
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'taxPercent': taxPercent,
    'unit': unit,
    'sku': sku,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
    'wholesalePrice': wholesalePrice,
  };

  factory ProductModel.fromFirestore(Map<String, dynamic> map) => ProductModel(
    id: map['id'],
    name: map['name'],
    description: map['description'] ?? '',
    price: (map['price'] as num).toDouble(),
    taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0,
    unit: map['unit'] ?? 'pcs',
    sku: map['sku'],
    createdAt: DateTime.parse(map['createdAt']),
    syncStatus: 'synced',
    userId: map['userId'],
    wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble(),
  );
}
