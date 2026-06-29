// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileModelAdapter extends TypeAdapter<ProfileModel> {
  @override
  final int typeId = 5;

  @override
  ProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileModel(
      userId: fields[0] as String,
      businessName: fields[1] as String,
      ownerName: fields[2] as String,
      email: fields[3] as String,
      phone: fields[4] as String,
      address: fields[5] as String,
      taxNumber: fields[6] as String?,
      logoPath: fields[7] as String?,
      currency: fields[8] as String,
      bankDetails: fields[9] as String?,
      invoicePrefix: fields[10] as String?,
      invoiceCounter: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.businessName)
      ..writeByte(2)
      ..write(obj.ownerName)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.taxNumber)
      ..writeByte(7)
      ..write(obj.logoPath)
      ..writeByte(8)
      ..write(obj.currency)
      ..writeByte(9)
      ..write(obj.bankDetails)
      ..writeByte(10)
      ..write(obj.invoicePrefix)
      ..writeByte(11)
      ..write(obj.invoiceCounter);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
