import 'package:hive/hive.dart';

part 'client_model.g.dart';

@HiveType(typeId: 1)
class ClientModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String address;

  @HiveField(5)
  String? companyName;

  @HiveField(6)
  String? taxNumber;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String syncStatus; // 'pending' | 'synced'

  @HiveField(9)
  String userId;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.companyName,
    this.taxNumber,
    required this.createdAt,
    this.syncStatus = 'pending',
    required this.userId,
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'companyName': companyName,
    'taxNumber': taxNumber,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
  };

  factory ClientModel.fromFirestore(Map<String, dynamic> map) => ClientModel(
    id: map['id'],
    name: map['name'],
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    address: map['address'] ?? '',
    companyName: map['companyName'],
    taxNumber: map['taxNumber'],
    createdAt: DateTime.parse(map['createdAt']),
    syncStatus: 'synced',
    userId: map['userId'],
  );

  ClientModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? companyName,
    String? taxNumber,
    String? syncStatus,
  }) {
    return ClientModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      companyName: companyName ?? this.companyName,
      taxNumber: taxNumber ?? this.taxNumber,
      createdAt: createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId,
    );
  }
}
