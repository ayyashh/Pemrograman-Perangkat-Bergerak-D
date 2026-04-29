import 'package:isar/isar.dart';
part 'models.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uid;
  late String name;
  late String email;
  late String role;
  late DateTime createdAt;
}

@collection
class AssetModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String assetId;

  late String name;
  late String description;
  late String category;
  late int quantity;
  late int availableQty;
  late bool isActive;
  String? imagePath; 
  late DateTime createdAt;

  @Backlink(to: 'asset')
  final borrows = IsarLinks<BorrowModel>();
}

@collection
class BorrowModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String borrowId;

  late String userId;
  late String assetId;
  late String assetName;
  late String userName;
  late DateTime startDate;
  late DateTime endDate;
  late String status;
  String? note;
  String? rejectionReason;
  String? returnProofPath;
  late DateTime createdAt;
  DateTime? updatedAt;

  final user = IsarLink<UserModel>();
  final asset = IsarLink<AssetModel>();
}
