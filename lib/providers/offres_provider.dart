import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offres_service.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import '../services/auth/real_auth_service.dart';

final offresServiceProvider = Provider<OffresService>((ref) {
  final baseUrl = AppConfig.apiBaseUrl; // ex: https://api.prod.tld/api
  return OffresService(
    baseUrl,
    getToken: () async => RealAuthService().token,
  );
});

class MesOffresState {
  final bool loading;
  final List<Map<String, dynamic>> items;
  final String? error;
  const MesOffresState({required this.loading, required this.items, this.error});
  MesOffresState copy({bool? loading, List<Map<String, dynamic>>? items, String? error}) =>
      MesOffresState(loading: loading ?? this.loading, items: items ?? this.items, error: error);
}


class MesOffresNotifier extends StateNotifier<MesOffresState> {
  MesOffresNotifier(this.ref) : super(const MesOffresState(loading: false, items: []));
  final Ref ref;

  Future<void> load() async {
    final me = ref.read(authProvider);
    if (!me.isAuthenticated || me.id == null) {
      state = state.copy(error: 'Non authentifié');
      return;
    }
    state = state.copy(loading: true, error: null);
    try {
      final service = ref.read(offresServiceProvider);
      final data = await service.listOffres();

      final myId = me.id ?? me.userId;
      final mine = (myId == null)
          ? data
          : data.where((o) {
        final uid = o['userId'] ?? o['user_id'];
        if (uid is int) return uid == myId;
        if (uid is String) return int.tryParse(uid) == myId;
        return false;
      }).toList();

      state = state.copy(loading: false, items: mine);
    } catch (e) {
      state = state.copy(loading: false, error: e.toString());
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    final me = ref.read(authProvider);
    if (me.id == null) throw Exception('Utilisateur introuvable');
    final service = ref.read(offresServiceProvider);

    // 🧩 impose l’owner côté client (adapte la clé selon ton back: fournisseurId / userId)
    final body = {
      ...payload,
      'fournisseurId': me.id, // ou 'userId': me.id
    };

    await service.createOffre(body);
    await load();
  }

  Future<void> update(int id, Map<String, dynamic> patch) async {
    final service = ref.read(offresServiceProvider);
    await service.updateOffre(id, patch);
    await load();
  }

  Future<void> toggle(int id) async {
    final service = ref.read(offresServiceProvider);
    await service.toggleDisponibilite(id);
    await load();
  }

  Future<void> remove(int id) async {
    final service = ref.read(offresServiceProvider);
    await service.deleteOffre(id);
    state = state.copy(items: state.items.where((e) => e['id'] != id).toList());
  }
}

final mesOffresProvider = StateNotifierProvider<MesOffresNotifier, MesOffresState>((ref) {
  final notifier = MesOffresNotifier(ref);
  // charge automatiquement au premier listen
  Future.microtask(() => notifier.load());
  return notifier;
});
