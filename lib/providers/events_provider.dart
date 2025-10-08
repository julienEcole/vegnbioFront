// Placez ce fichier dans : lib/providers/events_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/event_model.dart';
import 'package:vegnbio_front/services/events_service.dart';

/// Provider pour le service d'événements
final eventsServiceProvider = Provider<EventsService>((ref) {
  return EventsService();
});

/// Provider pour la liste des événements publics
final publicEventsProvider = FutureProvider<List<Event>>((ref) async {
  final eventsService = ref.read(eventsServiceProvider);
  return eventsService.fetchPublicEvents();
});

/// Provider pour un événement spécifique
final eventByIdProvider = FutureProvider.family<Event, int>((ref, id) async {
  final eventsService = ref.read(eventsServiceProvider);
  return eventsService.fetchEventById(id);
});