// lib/widgets/events/event_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_front/models/event_model.dart';
import 'package:vegnbio_front/services/events_admin_service.dart';
import 'package:vegnbio_front/widgets/events/event_form_screen.dart';

/// Dashboard d'administration des événements pour les restaurateurs
class EventAdminDashboard extends ConsumerStatefulWidget {
  const EventAdminDashboard({super.key});

  @override
  ConsumerState<EventAdminDashboard> createState() => _EventAdminDashboardState();
}

class _EventAdminDashboardState extends ConsumerState<EventAdminDashboard> {
  final EventsAdminService _eventsService = EventsAdminService();
  List<Event> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final events = await _eventsService.getAllEvents();
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration des Événements'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateEventDialog,
            tooltip: 'Créer un nouvel événement',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Actualiser la liste',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Wrapper centré : largeur max + marges latérales (évite le full-width en web)
  Widget _pageShell({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxWidth = 1100.0;
        final horizontal = constraints.maxWidth >= 1200
            ? 32.0
            : (constraints.maxWidth >= 900 ? 24.0 : 16.0);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 16),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des événements...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return _pageShell(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadEvents, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return _pageShell(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Aucun événement trouvé', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Commencez par créer votre premier événement', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showCreateEventDialog,
                icon: const Icon(Icons.add),
                label: const Text('Créer un événement'),
              ),
            ],
          ),
        ),
      );
    }

    // Liste scrollable avec RefreshIndicator, enveloppée dans le shell centré/stylé
    return _pageShell(
      child: RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) => _buildEventCard(_events[index]),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final now = DateTime.now();
    final isUpcoming = event.startAt.isAfter(now);
    final isOngoing = event.startAt.isBefore(now) && event.endAt.isAfter(now);

    Color statusColor = Colors.grey;
    String statusText = 'Passé';
    IconData statusIcon = Icons.history;

    if (isUpcoming) {
      statusColor = Colors.green;
      statusText = 'À venir';
      statusIcon = Icons.event_available;
    } else if (isOngoing) {
      statusColor = Colors.orange;
      statusText = 'En cours';
      statusIcon = Icons.event;
    }

    final surface = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4);

    return Card(
      clipBehavior: Clip.antiAlias, // pour des hit-tests propres
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : titre + badges statut & visibilité
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.titre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                // Badges à droite
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipBadge(
                      icon: statusIcon,
                      label: statusText,
                      bg: statusColor.withOpacity(0.12),
                      fg: statusColor,
                    ),
                    _ChipBadge(
                      icon: event.isPublic ? Icons.public : Icons.lock,
                      label: event.isPublic ? 'Public' : 'Privé',
                      bg: (event.isPublic ? Colors.blue : Colors.grey).withOpacity(0.12),
                      fg: event.isPublic ? Colors.blue : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Description
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Infos temps & capacité
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _InfoRow(icon: Icons.calendar_today, text: _formatDate(event.startAt)),
                _InfoRow(
                  icon: Icons.access_time,
                  text: '${_formatTime(event.startAt)} - ${_formatTime(event.endAt)}',
                ),
                _InfoRow(icon: Icons.people, text: '${event.capacity} places'),
              ],
            ),

            const SizedBox(height: 12),

            // Actions : alignées à droite, boutons colorés compacts (ne prennent pas toute la width)
            Row(
              children: [
                const Spacer(),
                // Modifier (couleur primaire)
                FilledButton.icon(
                  onPressed: () => _editEvent(event),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                // Supprimer (rouge)
                FilledButton.icon(
                  onPressed: () => _confirmDelete(event),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Supprimer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateEventDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventFormScreen()),
    ).then((_) => _loadEvents());
  }

  void _editEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventFormScreen(eventToEdit: event)),
    ).then((_) => _loadEvents());
  }

  void _confirmDelete(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer l\'événement "${event.titre}" ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEvent(event.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(int eventId) async {
    try {
      await _eventsService.deleteEvent(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement supprimé avec succès'), backgroundColor: Colors.green),
        );
        _loadEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Petits composants de style (UI only)

class _ChipBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  const _ChipBadge({required this.icon, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
