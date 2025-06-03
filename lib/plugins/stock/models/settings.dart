// lib/plugins/stock/models/settings.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ValuationMethod { FIFO, LIFO, WAC } // WAC = Coût Moyen Pondéré

class StockSettings {
  final String id;
  final String defaultUnitOfMeasure;
  final int defaultReorderThreshold;
  final ValuationMethod valuationMethod;
  final bool emailNotificationsEnabled;
  final bool inAppNotificationsEnabled;

  StockSettings({
    required this.id,
    required this.defaultUnitOfMeasure,
    required this.defaultReorderThreshold,
    required this.valuationMethod,
    required this.emailNotificationsEnabled,
    required this.inAppNotificationsEnabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'defaultUnitOfMeasure': defaultUnitOfMeasure,
      'defaultReorderThreshold': defaultReorderThreshold,
      'valuationMethod': valuationMethod.name,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'inAppNotificationsEnabled': inAppNotificationsEnabled,
    };
  }

  factory StockSettings.fromMap(String id, Map<String, dynamic> map) {
    return StockSettings(
      id: id,
      defaultUnitOfMeasure: map['defaultUnitOfMeasure'] as String? ?? '',
      defaultReorderThreshold: map['defaultReorderThreshold'] as int? ?? 0,
      valuationMethod: ValuationMethod.values.firstWhere(
            (e) => e.name == (map['valuationMethod'] as String? ?? 'FIFO'),
        orElse: () => ValuationMethod.FIFO,
      ),
      emailNotificationsEnabled: map['emailNotificationsEnabled'] as bool? ?? false,
      inAppNotificationsEnabled: map['inAppNotificationsEnabled'] as bool? ?? true,
    );
  }
}
