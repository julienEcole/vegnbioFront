// lib/providers/reports_admin_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/report.dart';
import 'package:vegnbio_front/providers/auth_provider.dart';
import 'package:vegnbio_front/services/reports_admin_service.dart';

/// Filtres d'affichage
class ReportsFilter {
  final String? status;
  final String? category;
  final String? targetType;
  final String? q;
  final int page;
  final int pageSize;

  const ReportsFilter({
    this.status,
    this.category,
    this.targetType,
    this.q,
    this.page = 1,
    this.pageSize = 20,
  });

  ReportsFilter copyWith({
    String? status,
    String? category,
    String? targetType,
    String? q,
    int? page,
    int? pageSize,
  }) =>
      ReportsFilter(
        status: status ?? this.status,
        category: category ?? this.category,
        targetType: targetType ?? this.targetType,
        q: q ?? this.q,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );
}

/// Service provider
final reportsAdminServiceProvider = Provider<ReportsAdminService>((ref) {
  return ReportsAdminService();
});

/// Filtres provider
final reportsFilterProvider = StateProvider<ReportsFilter>((ref) {
  return const ReportsFilter();
});

/// Liste des reports (auto-fetch)
final reportsListProvider = FutureProvider.autoDispose<ReportListResponse>((ref) async {
  final filter = ref.watch(reportsFilterProvider);
  final auth = ref.watch(authProvider);
  final token = auth.token;

  print('🔎 [reportsListProvider] start with filter: '
      'status=${filter.status} category=${filter.category} targetType=${filter.targetType} '
      'q=${filter.q} page=${filter.page}/${filter.pageSize}');

  if (token == null || token.isEmpty) {
    print('⛔ [reportsListProvider] token missing');
    throw Exception('Non authentifié : token manquant');
  }

  final svc = ref.watch(reportsAdminServiceProvider);
  final resp = await svc.listReports(
    token: token,
    status: filter.status,
    category: filter.category,
    targetType: filter.targetType,
    q: filter.q,
    page: filter.page,
    pageSize: filter.pageSize,
  );
  print('✅ [reportsListProvider] got ${resp.data.length} items (page ${resp.page})');
  return resp;
});

/// Action PATCH
final updateReportStatusProvider =
FutureProvider.family<void, ({int id, String status, String? note})>((ref, args) async {
  final auth = ref.watch(authProvider);
  final token = auth.token;
  if (token == null || token.isEmpty) {
    throw Exception('Non authentifié : token manquant');
  }
  final svc = ref.watch(reportsAdminServiceProvider);
  await svc.updateStatus(id: args.id, status: args.status, resolutionNote: args.note, token: token);
  // force refresh
  ref.invalidate(reportsListProvider);
});
