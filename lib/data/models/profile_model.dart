import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 5)
class ProfileModel extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String businessName;

  @HiveField(2)
  String ownerName;

  @HiveField(3)
  String email;

  @HiveField(4)
  String phone;

  @HiveField(5)
  String address;

  @HiveField(6)
  String? taxNumber;

  @HiveField(7)
  String? logoPath; // local path

  @HiveField(8)
  String currency;

  @HiveField(9)
  String? bankDetails;

  @HiveField(10)
  String? invoicePrefix; // e.g. 'INV-'

  @HiveField(11)
  int invoiceCounter;

  ProfileModel({
    required this.userId,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    this.taxNumber,
    this.logoPath,
    this.currency = 'PKR',
    this.bankDetails,
    this.invoicePrefix = 'INV-',
    this.invoiceCounter = 1,
  });

  String get nextInvoiceNumber =>
      '${invoicePrefix ?? 'INV-'}${invoiceCounter.toString().padLeft(4, '0')}';

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'businessName': businessName,
    'ownerName': ownerName,
    'email': email,
    'phone': phone,
    'address': address,
    'taxNumber': taxNumber,
    'currency': currency,
    'bankDetails': bankDetails,
    'invoicePrefix': invoicePrefix,
    'invoiceCounter': invoiceCounter,
  };
}
