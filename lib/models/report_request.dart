// lib/models/report_request.dart
import 'package:vegnbio_front/models/report.dart';

class ReportRequest {
  final ReportTarget targetType;
  final int targetId;
  final int? restaurantId;
  final ReportCategory category;
  final String message;

  const ReportRequest({
    required this.targetType,
    required this.targetId,
    required this.restaurantId,
    required this.category,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'targetType': targetType.name,
    'targetId': targetId,
    'restaurantId': restaurantId,
    'category': category.name,
    'message': message,
  };
}
