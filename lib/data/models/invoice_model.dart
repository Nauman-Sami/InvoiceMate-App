import 'package:hive/hive.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 3)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  String description;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  double unitPrice;

  @HiveField(5)
  double taxPercent;

  @HiveField(6)
  String unit;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxPercent = 0,
    this.unit = 'pcs',
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (taxPercent / 100);
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'taxPercent': taxPercent,
    'unit': unit,
  };

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
    productId: map['productId'],
    productName: map['productName'],
    description: map['description'] ?? '',
    quantity: (map['quantity'] as num).toDouble(),
    unitPrice: (map['unitPrice'] as num).toDouble(),
    taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0,
    unit: map['unit'] ?? 'pcs',
  );
}

@HiveType(typeId: 4)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String invoiceNumber;

  @HiveField(2)
  String clientId;

  @HiveField(3)
  String clientName;

  @HiveField(4)
  String clientEmail;

  @HiveField(5)
  String clientAddress;

  @HiveField(6)
  List<InvoiceItem> items;

  @HiveField(7)
  DateTime issueDate;

  @HiveField(8)
  DateTime dueDate;

  @HiveField(9)
  String status; // Draft | Sent | Paid | Overdue | Cancelled

  @HiveField(10)
  double discountPercent;

  @HiveField(11)
  String? notes;

  @HiveField(12)
  String currency;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  String syncStatus; // pending | synced

  @HiveField(15)
  String userId;

  @HiveField(16)
  double? paidAmount;

  @HiveField(17)
  DateTime? paidAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientAddress,
    required this.items,
    required this.issueDate,
    required this.dueDate,
    this.status = 'Draft',
    this.discountPercent = 0,
    this.notes,
    this.currency = 'PKR',
    required this.createdAt,
    this.syncStatus = 'pending',
    required this.userId,
    this.paidAmount,
    this.paidAt,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalTax => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get grandTotal => subtotal + totalTax - discountAmount;
  double get balanceDue => grandTotal - (paidAmount ?? 0);
  bool get isOverdue =>
      status != 'Paid' && status != 'Cancelled' && dueDate.isBefore(DateTime.now());

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'clientId': clientId,
    'clientName': clientName,
    'clientEmail': clientEmail,
    'clientAddress': clientAddress,
    'items': items.map((e) => e.toMap()).toList(),
    'issueDate': issueDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'status': status,
    'discountPercent': discountPercent,
    'notes': notes,
    'currency': currency,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
    'paidAmount': paidAmount,
    'paidAt': paidAt?.toIso8601String(),
  };

  factory InvoiceModel.fromFirestore(Map<String, dynamic> map) => InvoiceModel(
    id: map['id'],
    invoiceNumber: map['invoiceNumber'],
    clientId: map['clientId'],
    clientName: map['clientName'],
    clientEmail: map['clientEmail'] ?? '',
    clientAddress: map['clientAddress'] ?? '',
    items: (map['items'] as List)
        .map((e) => InvoiceItem.fromMap(e as Map<String, dynamic>))
        .toList(),
    issueDate: DateTime.parse(map['issueDate']),
    dueDate: DateTime.parse(map['dueDate']),
    status: map['status'],
    discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
    notes: map['notes'],
    currency: map['currency'] ?? 'PKR',
    createdAt: DateTime.parse(map['createdAt']),
    syncStatus: 'synced',
    userId: map['userId'],
    paidAmount: (map['paidAmount'] as num?)?.toDouble(),
    paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
  );
}
