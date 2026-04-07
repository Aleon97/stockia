import 'package:stockia/domain/entities/stock_alert_entity.dart';

abstract class StockAlertRepository {
  Future<List<StockAlertEntity>> getActiveAlerts(String tenantId);
  Stream<List<StockAlertEntity>> watchActiveAlerts(String tenantId);
  Future<void> createAlert(StockAlertEntity alert);
  Future<void> resolveAlert(String alertId);
  Future<void> deleteAlertsByProductId(String productId, String tenantId);
}
