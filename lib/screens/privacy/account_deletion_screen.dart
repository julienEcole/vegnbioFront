import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_deletion_service.dart';
import '../../services/auth/real_auth_service.dart';

/// Écran de gestion de la suppression de compte et des données utilisateur
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  final UserDeletionService _deletionService = UserDeletionService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = RealAuthService();
      final token = authService.token;
      
      if (token == null) {
        throw Exception('Vous devez être connecté');
      }

      final stats = await _deletionService.getUserDataStats(token);
      
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anonymiser mes données personnelles'),
        content: const Text(
          'Cette action anonymisera vos informations personnelles (nom et prénom).\n\n'
          'Votre email et mot de passe seront conservés : vous pourrez toujours vous connecter.\n\n'
          'Vos commandes payées seront conservées de manière anonyme pour des raisons comptables.\n\n'
          '⚠️ Vous serez automatiquement déconnecté après cette opération.\n\n'
          'Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Deuxième confirmation
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Dernière confirmation'),
        content: const Text(
          'Voulez-vous vraiment anonymiser vos données personnelles (nom et prénom) ?\n\n'
          'Vous serez déconnecté mais pourrez vous reconnecter immédiatement avec votre email et mot de passe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('OUI, ANONYMISER'),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true) return;

    // Effectuer la suppression
    try {
      final authService = RealAuthService();
      final token = authService.token;
      
      if (token == null) {
        throw Exception('Token invalide');
      }

      await _deletionService.deleteUserData(token);

      if (!mounted) return;

      // Déconnecter l'utilisateur
      await ref.read(authProvider.notifier).logout();

      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vos données personnelles ont été anonymisées avec succès. Vous pouvez toujours vous reconnecter.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Rediriger vers la page d'accueil
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action supprimera DÉFINITIVEMENT votre compte et TOUTES vos données :\n\n'
          '• Informations personnelles\n'
          '• Toutes vos commandes (payées ou non)\n'
          '• Tout votre historique\n\n'
          '⚠️ Vous serez automatiquement déconnecté et ne pourrez PLUS JAMAIS vous reconnecter.\n\n'
          'Cette action est IRRÉVERSIBLE et TOUTES vos données seront perdues.\n\n'
          'Êtes-vous ABSOLUMENT SÛR de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Deuxième confirmation avec texte à saisir
    final textController = TextEditingController();
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ CONFIRMATION FINALE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette action est DÉFINITIVE et IRRÉVERSIBLE.\n\n'
              'Vous serez déconnecté et ne pourrez JAMAIS vous reconnecter.\n\n'
              'Pour confirmer, tapez "SUPPRIMER" ci-dessous :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Tapez SUPPRIMER',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text == 'SUPPRIMER') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez taper exactement "SUPPRIMER"'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              foregroundColor: Colors.white,
            ),
            child: const Text('SUPPRIMER DÉFINITIVEMENT'),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true) return;

    // Effectuer la suppression
    try {
      final authService = RealAuthService();
      final token = authService.token;
      
      if (token == null) {
        throw Exception('Token invalide');
      }

      await _deletionService.deleteAccount(token);

      if (!mounted) return;

      // Déconnecter l'utilisateur
      await ref.read(authProvider.notifier).logout();

      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre compte a été supprimé définitivement'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Rediriger vers la page d'accueil
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de mes données'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStats,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avertissement
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700], size: 32),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Attention : Les actions de suppression sont IRRÉVERSIBLES',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Statistiques
                      _buildSection(
                        'Vos données actuelles',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatRow(Icons.shopping_bag, 'Commandes totales', 
                                _stats?['stats']?['totalOrders']?.toString() ?? '0'),
                            _buildStatRow(Icons.check_circle, 'Commandes payées', 
                                _stats?['stats']?['paidOrders']?.toString() ?? '0'),
                            _buildStatRow(Icons.pending, 'Commandes en attente', 
                                _stats?['stats']?['unpaidOrders']?.toString() ?? '0'),
                            const Divider(height: 24),
                            Text(
                              'Email : ${_stats?['stats']?['personalData']?['email'] ?? ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Compte créé le : ${_stats?['stats']?['personalData']?['dateCreation'] ?? ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Option 1: Anonymiser les données (conserver les commandes payées et le compte)
                      _buildDeletionOption(
                        title: '1. Anonymiser mes données personnelles',
                        description: _stats?['deletionOptions']?['deleteData']?['description'] ?? '',
                        color: Colors.orange,
                        icon: Icons.person_remove,
                        willDelete: _stats?['deletionOptions']?['deleteData']?['willDelete'] ?? [],
                        willKeep: _stats?['deletionOptions']?['deleteData']?['willKeep'] ?? '',
                        willRemove: _stats?['deletionOptions']?['deleteData']?['willRemove'] ?? '',
                        onPressed: _handleDeleteData,
                        buttonText: 'Anonymiser mes données',
                      ),
                      const SizedBox(height: 24),

                      // Option 2: Supprimer complètement le compte
                      _buildDeletionOption(
                        title: '2. Supprimer définitivement mon compte',
                        description: _stats?['deletionOptions']?['deleteAccount']?['description'] ?? '',
                        color: Colors.red[900]!,
                        icon: Icons.delete_forever,
                        willDelete: _stats?['deletionOptions']?['deleteAccount']?['willDelete'] ?? [],
                        willKeep: _stats?['deletionOptions']?['deleteAccount']?['willKeep'] ?? '',
                        willRemove: _stats?['deletionOptions']?['deleteAccount']?['willRemove'] ?? '',
                        onPressed: _handleDeleteAccount,
                        buttonText: 'Supprimer mon compte',
                      ),
                      const SizedBox(height: 24),

                      // Informations RGPD
                      _buildSection(
                        'Vos droits (RGPD)',
                        const Text(
                          'Conformément au Règlement Général sur la Protection des Données (RGPD), '
                          'vous avez le droit de demander l\'accès, la rectification, la suppression '
                          'et la portabilité de vos données personnelles.\n\n'
                          'Ces options de suppression vous permettent d\'exercer votre droit à l\'effacement '
                          '(droit à l\'oubli) de manière autonome.\n\n'
                          'Pour toute question, contactez-nous à : privacy@vegnbio.com',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDeletionOption({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required List<dynamic> willDelete,
    required String willKeep,
    required String willRemove,
    required VoidCallback onPressed,
    required String buttonText,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            
            // Ce qui sera supprimé
            Text(
              'Sera supprimé :',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            ...willDelete.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.remove_circle, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Text(item.toString()),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Text(
              '• $willRemove',
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 12),
            
            // Ce qui sera conservé
            Text(
              'Sera conservé :',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• $willKeep',
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 16),
            
            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

