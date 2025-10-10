enum ReportStatus { open, in_review, resolved, rejected }
enum ReportTarget { menu, evenement, offre, restaurant, autre }
enum ReportCategory { inapproprie, securite, mensonger, fraude, autre }

ReportStatus reportStatusFrom(String s) =>
    ReportStatus.values.firstWhere((e)=>e.name==s, orElse: ()=>ReportStatus.open);
ReportTarget reportTargetFrom(String s) =>
    ReportTarget.values.firstWhere((e)=>e.name==s, orElse: ()=>ReportTarget.autre);
ReportCategory reportCategoryFrom(String s) =>
    ReportCategory.values.firstWhere((e)=>e.name==s, orElse: ()=>ReportCategory.autre);

class Report {
  final int id;
  final ReportTarget targetType;
  final int targetId;
  final int? restaurantId;
  final ReportCategory category;
  final String message;
  final ReportStatus status;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? reporterEmail;   // si le back l’envoie
  final String? moderatorEmail;  // si le back l’envoie

  Report({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.restaurantId,
    required this.category,
    required this.message,
    required this.status,
    required this.resolutionNote,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
    this.reporterEmail,
    this.moderatorEmail,
  });

  factory Report.fromJson(Map<String, dynamic> j) => Report(
    id: j['id'] as int,
    targetType: reportTargetFrom(j['targetType'] as String),
    targetId: j['targetId'] as int,
    restaurantId: j['restaurantId'] as int?,
    category: reportCategoryFrom(j['category'] as String),
    message: j['message'] as String,
    status: reportStatusFrom(j['status'] as String),
    resolutionNote: j['resolutionNote'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    resolvedAt: j['resolvedAt'] != null ? DateTime.parse(j['resolvedAt'] as String) : null,
    reporterEmail: j['reporter']?['email'] as String?,
    moderatorEmail: j['moderator']?['email'] as String?,
  );
}

class ReportListResponse {
  final List<Report> data;
  final int total;
  final int page;
  final int pageSize;

  ReportListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ReportListResponse.fromJson(Map<String, dynamic> json) {
    return ReportListResponse(
      data: (json['data'] as List<dynamic>)
          .map((r) => Report.fromJson(r))
          .toList(),
      total: json['total'] ?? (json['data']?.length ?? 0),
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? (json['data']?.length ?? 0),
    );
  }

}
