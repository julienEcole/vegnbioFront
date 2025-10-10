import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/report.dart';
import 'package:vegnbio_front/services/reporting_service.dart';
import 'package:vegnbio_front/providers/auth_provider.dart'; // ✅ IMPORT


/// Service DI
final reportingServiceProvider = Provider<ReportingService>((ref) {
  return ReportingService();
});

/// Liste des reports (admin/restaurateur)
final reportsListProvider = FutureProvider<ReportListResponse>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.token; // adapte si ton AuthState expose un autre champ
  if (token == null || token.isEmpty) {
    throw Exception('Token manquant (auth requise)');
  }
  final svc = ref.watch(reportingServiceProvider);
  return await svc.fetchReports(token: token);
});

/*
final reportingServiceProvider = Provider<ReportingService>((ref) {
  return ReportingService();
});

final sendReportProvider = FutureProvider.family<void, ReportRequest>((ref, req) async {
  final svc = ref.read(reportingServiceProvider);

  final auth = ref.read(authProvider);          // ✅ on lit l’état d’auth
  final token = auth.token;                     // ✅ utilise juste "token"
  if (token == null || token.isEmpty) {
    throw Exception('Vous devez être connecté pour signaler.');
  }

  await svc.createReport(req, token: token);    // ✅ on passe le token requis
});

// Liste des reports (admin)
final reportsListProvider = FutureProvider<ReportListResponse>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.token ?? '';
  final service = ref.watch(reportingServiceProvider);
  return await service.fetchReports(token: token);
});


final reportsListProvider = FutureProvider<ReportListResponse>((ref) async {
  final service = ref.read(reportingServiceProvider);
  return await service.fetchReports();
});


final reportsListProvider = FutureProvider<ReportListResponse>((ref) async {
  final service = ref.watch(reportingServiceProvider);
  return await service.fetchReports();
});
*/