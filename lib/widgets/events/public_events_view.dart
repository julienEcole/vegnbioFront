import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/event_model.dart';
import 'package:vegnbio_front/providers/events_provider.dart';
import 'package:vegnbio_front/widgets/events/reservation_modal.dart';
import 'package:vegnbio_front/widgets/common/report_event_modal.dart';

/// Vue publique des événements
class PublicEventsView extends ConsumerWidget {
  const PublicEventsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(publicEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implémenter la navigation vers la connexion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité de connexion à implémenter'),
                ),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Se connecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),

      // ✅ Ajout d'un wrapper responsive pour limiter la largeur et ajouter des marges
      body: _wrapPage(
        context: context,
        child: Column(
          children: [
            // Message informatif
            _buildInfoBanner(context),
            // Contenu des événements
            Expanded(
              child: eventsAsync.when(
                data: (events) => _buildEventsContent(context, events),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(context, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wrapper responsive : centre le contenu, limite la largeur et ajoute des marges latérales
  Widget _wrapPage({required BuildContext context, required Widget child}) {
    final width = MediaQuery.of(context).size.width;

    // Points de rupture simples (tu peux ajuster au besoin)
    const double maxContentWidth = 1100; // largeur max sur desktop
    final double horizontalPadding =
    width >= 1200 ? 32 : (width >= 900 ? 24 : 16);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }

  /// Bannière d'information en haut de page
  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vue publique des événements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connectez-vous pour accéder aux fonctionnalités complètes',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement des événements...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// État d'erreur
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Forcer le rechargement
                // ref.invalidate(publicEventsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Contenu principal avec la liste des événements
  Widget _buildEventsContent(BuildContext context, List<Event> events) {
    if (events.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Événements à venir',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Découvrez nos prochains événements et animations dans nos restaurants.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        ...events.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildEventCard(context, event),
        )),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implémenter la navigation vers la connexion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité de connexion à implémenter'),
                ),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Se connecter pour plus d\'informations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// État vide (aucun événement)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun événement disponible',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Revenez bientôt pour découvrir nos prochains événements.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'événement
  Widget _buildEventCard(BuildContext context, Event event) {
    // Format de date sans dépendance intl
    final day = event.startAt.day.toString().padLeft(2, '0');
    final month = _getMonthName(event.startAt.month);
    final year = event.startAt.year;
    final formattedDate = '$day $month $year';

    final startHour = event.startAt.hour.toString().padLeft(2, '0');
    final startMinute = event.startAt.minute.toString().padLeft(2, '0');
    final endHour = event.endAt.hour.toString().padLeft(2, '0');
    final endMinute = event.endAt.minute.toString().padLeft(2, '0');
    final formattedTime = '$startHour:$startMinute - $endHour:$endMinute';

    // Icône et couleur basées sur le titre
    IconData icon = Icons.event;
    Color color = Colors.blue;

    if (event.titre.toLowerCase().contains('cuisine') ||
        event.titre.toLowerCase().contains('dégustation')) {
      icon = Icons.restaurant_menu;
      color = Colors.green;
    } else if (event.titre.toLowerCase().contains('atelier')) {
      icon = Icons.school;
      color = Colors.orange;
    } else if (event.titre.toLowerCase().contains('marché') ||
        event.titre.toLowerCase().contains('producteur')) {
      icon = Icons.local_grocery_store;
      color = Colors.blue;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReservationModal(context, event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.titre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.capacity} places',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showReportModal(context, event),
                              icon: const Icon(Icons.flag, color: Colors.red),
                              label: const Text('Signaler'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bouton de réservation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReservationModal(context, event),
                  icon: const Icon(Icons.event_available),
                  label: const Text('Réserver une place'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche la modal de réservation
  void _showReservationModal(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => ReservationModal(event: event),
    );
  }

  /// Retourne le nom du mois en français
  String _getMonthName(int month) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return months[month - 1];
  }

  void _showReportModal(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (_) => ReportEventModal(
        eventId: event.id,                 // assure-toi que Event a bien un id
        restaurantId: event.restaurantId,  // si dispo dans ton modèle (sinon enlève)
      ),
    );
  }


}
