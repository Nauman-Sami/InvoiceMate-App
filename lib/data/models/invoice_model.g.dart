// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceItemAdapter extends TypeAdapter<InvoiceItem> {
  @override
  final int typeId = 3;

  @override
  InvoiceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceItem(
      productId: fields[0] as String,
      productName: fields[1] as String,
      description: fields[2] as String,
      quantity: fields[3] as double,
      unitPrice: fields[4] as double,
      taxPercent: fields[5] as double,
      unit: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unitPrice)
      ..writeByte(5)
      ..write(obj.taxPercent)
      ..writeByte(6)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvoiceModelAdapter extends TypeAdapter<InvoiceModel> {
  @override
  final int typeId = 4;

  @override
  InvoiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceModel(
      id: fields[0] as String,
      invoiceNumber: fields[1] as String,
      clientId: fields[2] as String,
      clientName: fields[3] as String,
      clientEmail: fields[4] as String,
      clientAddress: fields[5] as String,
      items: (fields[6] as List).cast<InvoiceItem>(),
      issueDate: fields[7] as DateTime,
      dueDate: fields[8] as DateTime,
      status: fields[9] as String,
      discountPercent: fields[10] as double,
      notes: fields[11] as String?,
      currency: fields[12] as String,
      createdAt: fields[13] as DateTime,
      syncStatus: fields[14] as String,
      userId: fields[15] as String,
      paidAmount: fields[16] as double?,
      paidAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.clientName)
      ..writeByte(4)
      ..write(obj.clientEmail)
      ..writeByte(5)
      ..write(obj.clientAddress)
      ..writeByte(6)
      ..write(obj.items)
      ..writeByte(7)
      ..write(obj.issueDate)
      ..writeByte(8)
      ..write(obj.dueDate)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.discountPercent)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.currency)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.syncStatus)
      ..writeByte(15)
      ..write(obj.userId)
      ..writeByte(16)
      ..write(obj.paidAmount)
      ..writeByte(17)
      ..write(obj.paidAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
