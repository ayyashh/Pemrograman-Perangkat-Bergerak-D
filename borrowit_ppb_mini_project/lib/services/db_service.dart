import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../models/models.dart';

class DbService {
  static late Isar _db;
  static final _fs = fs.FirebaseFirestore.instance;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _db = await Isar.open(
      [UserModelSchema, AssetModelSchema, BorrowModelSchema],
      directory: dir.path,
    );
  }

  // ── USER ──────────────────────────────────────────
  static Future<UserModel?> getUser(String uid) =>
      _db.userModels.where().uidEqualTo(uid).findFirst();

  static Future<void> saveUser(UserModel u) =>
      _db.writeTxn(() => _db.userModels.put(u));

  // ── ASSETS ────────────────────────────────────────
  static Future<List<AssetModel>> getAssets() =>
      _db.assetModels.where().findAll();

  static Future<AssetModel?> getAssetById(String assetId) =>
      _db.assetModels.where().assetIdEqualTo(assetId).findFirst();

  static Future<void> saveAsset(AssetModel a) =>
      _db.writeTxn(() => _db.assetModels.put(a));

  static Future<void> deleteAssetLocal(int id) =>
      _db.writeTxn(() => _db.assetModels.delete(id));

  static Future<List<AssetModel>> syncAssets() async {
    final snap = await _fs.collection('assets').get();
    for (final doc in snap.docs) {
      final d = doc.data();
      final existing = await getAssetById(doc.id) ?? AssetModel();
      existing
        ..assetId = doc.id
        ..name = d['name'] ?? ''
        ..description = d['description'] ?? ''
        ..category = d['category'] ?? ''
        ..quantity = (d['quantity'] ?? 1) as int
        ..availableQty = (d['availableQty'] ?? 1) as int
        ..isActive = d['isActive'] ?? true
        ..createdAt = DateTime.tryParse(d['createdAt'] ?? '') ?? DateTime.now();
      await saveAsset(existing);
    }
    return getAssets();
  }

  static Future<String> addAsset(AssetModel a) async {
    final ref = _fs.collection('assets').doc();
    await ref.set({
      'name': a.name, 'description': a.description,
      'category': a.category, 'quantity': a.quantity,
      'availableQty': a.availableQty, 'isActive': a.isActive,
      'createdAt': a.createdAt.toIso8601String(),
    });
    a.assetId = ref.id;
    await saveAsset(a);
    return ref.id;
  }

  static Future<void> updateAsset(AssetModel a) async {
    await _fs.collection('assets').doc(a.assetId).update({
      'name': a.name, 'description': a.description,
      'category': a.category, 'quantity': a.quantity,
      'availableQty': a.availableQty, 'isActive': a.isActive,
    });
    await saveAsset(a);
  }

  static Future<void> deleteAsset(AssetModel a) async {
    await _fs.collection('assets').doc(a.assetId).delete();
    await deleteAssetLocal(a.id);
  }

  // ── BORROWS ───────────────────────────────────────
  static Future<List<BorrowModel>> getBorrowsByUser(String uid) =>
      _db.borrowModels.filter().userIdEqualTo(uid).sortByCreatedAtDesc().findAll();

  static Future<List<BorrowModel>> getAllBorrows() =>
      _db.borrowModels.where().sortByCreatedAtDesc().findAll();

  static Future<BorrowModel?> getBorrowById(String borrowId) =>
      _db.borrowModels.where().borrowIdEqualTo(borrowId).findFirst();

  static Future<void> saveBorrow(BorrowModel b) =>
      _db.writeTxn(() => _db.borrowModels.put(b));

  static Future<bool> hasConflict(String assetId, DateTime start, DateTime end,
      {String? excludeId}) async {
    final list = await _db.borrowModels
        .filter()
        .assetIdEqualTo(assetId)
        .not().statusEqualTo('rejected')
        .not().statusEqualTo('returned')
        .findAll();
    for (final b in list) {
      if (b.borrowId == excludeId) continue;
      if (start.isBefore(b.endDate) && end.isAfter(b.startDate)) return true;
    }
    return false;
  }

  static Future<String> createBorrow({
    required UserModel user,
    required AssetModel asset,
    required DateTime start,
    required DateTime end,
    String? note,
  }) async {
    final ref = _fs.collection('borrows').doc();
    final now = DateTime.now();
    await ref.set({
      'userId': user.uid, 'assetId': asset.assetId,
      'assetName': asset.name, 'userName': user.name,
      'startDate': start.toIso8601String(), 'endDate': end.toIso8601String(),
      'status': 'pending', 'note': note,
      'createdAt': now.toIso8601String(),
    });

    final borrow = BorrowModel()
      ..borrowId = ref.id ..userId = user.uid ..assetId = asset.assetId
      ..assetName = asset.name ..userName = user.name
      ..startDate = start ..endDate = end ..status = 'pending'
      ..note = note ..createdAt = now;

    await saveBorrow(borrow);

    final saved = await getBorrowById(ref.id);
    if (saved != null) {
      saved.user.value = user;
      saved.asset.value = asset;
      await _db.writeTxn(() async {
        await saved.user.save();
        await saved.asset.save();
      });
    }
    return ref.id;
  }

  static Future<void> syncBorrows({String? userId}) async {
    fs.Query<Map<String, dynamic>> q = _fs.collection('borrows');
    if (userId != null) q = q.where('userId', isEqualTo: userId);
    final snap = await q.get();
    for (final doc in snap.docs) {
      final d = doc.data();
      final existing = await getBorrowById(doc.id) ?? BorrowModel();
      existing
        ..borrowId = doc.id ..userId = d['userId'] ?? ''
        ..assetId = d['assetId'] ?? '' ..assetName = d['assetName'] ?? ''
        ..userName = d['userName'] ?? ''
        ..startDate = DateTime.parse(d['startDate'])
        ..endDate = DateTime.parse(d['endDate'])
        ..status = d['status'] ?? 'pending'
        ..note = d['note'] ..rejectionReason = d['rejectionReason']
        ..createdAt = DateTime.parse(d['createdAt'])
        ..updatedAt = d['updatedAt'] != null ? DateTime.parse(d['updatedAt']) : null;
      await saveBorrow(existing);
    }
  }

  static Future<void> updateBorrowStatus(String borrowId, String status,
      {String? reason}) async {
    final data = <String, dynamic>{
      'status': status, 'updatedAt': DateTime.now().toIso8601String(),
      'rejectionReason': ?reason,
    };
    await _fs.collection('borrows').doc(borrowId).update(data);
    final b = await getBorrowById(borrowId);
    if (b != null) {
      b.status = status;
      b.updatedAt = DateTime.now();
      if (reason != null) b.rejectionReason = reason;
      await saveBorrow(b);
    }
  }

  static Future<void> confirmReturn(String borrowId, {String? proofPath}) async {
    await _fs.collection('borrows').doc(borrowId)
        .update({'status': 'returned', 'updatedAt': DateTime.now().toIso8601String()});
    final b = await getBorrowById(borrowId);
    if (b != null) {
      b.status = 'returned';
      b.updatedAt = DateTime.now();
      if (proofPath != null) b.returnProofPath = proofPath;
      await saveBorrow(b);
    }
  }
}
