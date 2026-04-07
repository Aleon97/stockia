import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/domain/repositories/stock_alert_repository.dart';

class StockAlertRepositoryImpl implements StockAlertRepository {
  final FirebaseFirestore _firestore;

  StockAlertRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('stock_alerts');

  @override
  Future<List<StockAlertEntity>> getActiveAlerts(String tenantId) async {
    final snapshot = await _collection
        .where('tenantId', isEqualTo: tenantId)
        .get();

    final alerts = snapshot.docs
        .map((doc) => StockAlertEntity.fromFirestore(doc))
        .where((a) => !a.isResolved)
        .toList();
    alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return alerts;
  }

  @override
  Stream<List<StockAlertEntity>> watchActiveAlerts(String tenantId) {
    return _collection.where('tenantId', isEqualTo: tenantId).snapshots().map((
      snapshot,
    ) {
      final alerts = snapshot.docs
          .map((doc) => StockAlertEntity.fromFirestore(doc))
          .where((a) => !a.isResolved)
          .toList();
      alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alerts;
    });
  }

  @override
  Future<void> createAlert(StockAlertEntity alert) async {
    await _collection.add(alert.toMap());
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    await _collection.doc(alertId).update({
      'isResolved': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> deleteAlertsByProductId(
    String productId,
    String tenantId,
  ) async {
    final snapshot = await _collection
        .where('tenantId', isEqualTo: tenantId)
        .where('productId', isEqualTo: productId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
