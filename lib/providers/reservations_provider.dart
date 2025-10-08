// Placez ce fichier dans : lib/providers/reservations_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/reservation_model.dart';
import 'package:vegnbio_front/services/reservations_service.dart';

/// Provider pour le service de réservations
final reservationsServiceProvider = Provider<ReservationsService>((ref) {
  return ReservationsService();
});

/// Provider pour créer une réservation
/// Utilise AsyncNotifier pour gérer l'état de chargement
class ReservationNotifier extends AutoDisposeAsyncNotifier<Reservation?> {
  @override
  Future<Reservation?> build() async {
    return null;
  }

  /// Crée une réservation
  Future<void> createReservation(
    int eventId,
    ReservationRequest request,
  ) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final service = ref.read(reservationsServiceProvider);
      return await service.createReservation(eventId, request);
    });
  }

  /// Réinitialise l'état
  void reset() {
    state = const AsyncValue.data(null);
  }
}

final reservationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ReservationNotifier, Reservation?>(
  () => ReservationNotifier(),
);