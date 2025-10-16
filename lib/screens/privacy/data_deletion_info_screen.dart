import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page d'information publique sur la suppression de compte et des données
/// Accessible à tous les utilisateurs (connectés ou non)
class DataDeletionInfoScreen extends StatelessWidget {
  const DataDeletionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppression de compte et de données'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Vos droits RGPD - Gestion de vos données personnelles',
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

            _buildSection(
              '1. Introduction',
              'Conformément au Règlement Général sur la Protection des Données (RGPD), vous avez le droit de gérer vos données personnelles. '
              'Veg\'N Bio vous permet de supprimer ou anonymiser vos données à tout moment.',
            ),

            _buildSection(
              '2. Les deux options disponibles',
              'Vous disposez de deux options pour gérer vos données personnelles :',
            ),

            // Option 1 - Carte
            Card(
              elevation: 2,
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.orange[700], size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Option 1 : Anonymiser mes données',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cette option anonymise vos informations personnelles tout en conservant votre capacité à vous connecter.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildListItem('Sera supprimé :', Colors.red[700]!),
                    _buildSubItem('• Votre nom et prénom', Colors.red[700]!),
                    _buildSubItem('• Vos commandes non payées', Colors.red[700]!),
                    const SizedBox(height: 8),
                    _buildListItem('Sera conservé :', Colors.green[700]!),
                    _buildSubItem('• Votre email et mot de passe', Colors.green[700]!),
                    _buildSubItem('• Vos commandes payées (anonymisées)', Colors.green[700]!),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '✓ Vous pourrez toujours vous reconnecter avec votre email',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Option 2 - Carte
            Card(
              elevation: 2,
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red[900], size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Option 2 : Supprimer mon compte',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cette option SUPPRIME DÉFINITIVEMENT votre compte de la base de données. Les commandes payées sont conservées de manière anonyme.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildListItem('Sera supprimé :', Colors.red[900]!),
                    _buildSubItem('• Votre compte complet (supprimé de la base de données)', Colors.red[900]!),
                    _buildSubItem('• Toutes vos informations personnelles', Colors.red[900]!),
                    _buildSubItem('• Vos commandes non payées', Colors.red[900]!),
                    const SizedBox(height: 8),
                    _buildListItem('Sera conservé (anonyme) :', Colors.green[700]!),
                    _buildSubItem('• Vos commandes payées (anonymisées)', Colors.green[700]!),
                    _buildSubItem('• Conservées pour conformité légale (RGPD + obligations fiscales)', Colors.green[700]!),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Les commandes payées doivent être conservées pour des raisons comptables et légales, mais elles seront totalement dissociées de votre identité.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '⚠️ Action IRRÉVERSIBLE - Vous ne pourrez plus vous reconnecter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              '3. Comment supprimer mon compte ou mes données ?',
              'Pour accéder aux options de suppression, vous devez être connecté à votre compte.',
            ),

            // Instructions étape par étape
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Étapes à suivre :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Connectez-vous à votre compte'),
                    _buildStep('2', 'Accédez à votre profil (icône utilisateur)'),
                    _buildStep('3', 'Cliquez sur "Gérer mes données personnelles"'),
                    _buildStep('4', 'Consultez vos statistiques de données'),
                    _buildStep('5', 'Choisissez l\'option qui vous convient'),
                    _buildStep('6', 'Confirmez votre choix (double confirmation requise)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              '4. Sécurité et confirmations',
              'Pour votre protection, nous vous demandons de confirmer votre décision plusieurs fois :\n\n'
              '• Première confirmation : Vous acceptez les conséquences\n'
              '• Deuxième confirmation : Vous confirmez définitivement\n'
              '• Pour la suppression complète : Vous devez taper "SUPPRIMER"\n\n'
              'Ces étapes garantissent que la suppression est bien volontaire.',
            ),

            _buildSection(
              '5. Que se passe-t-il après la suppression ?',
              '',
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Après anonymisation des données (Option 1) :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Vous êtes automatiquement déconnecté'),
                  const Text('• Vous pouvez vous reconnecter immédiatement'),
                  const Text('• Votre profil affiche "Utilisateur Anonyme"'),
                  const Text('• Vos commandes payées restent (anonymisées)'),
                  const SizedBox(height: 16),
                  const Text(
                    'Après suppression complète du compte (Option 2) :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Vous êtes automatiquement déconnecté'),
                  const Text('• Votre compte est complètement SUPPRIMÉ de la base de données'),
                  const Text('• Vous ne pouvez PLUS JAMAIS vous reconnecter'),
                  const Text('• Toutes vos données personnelles sont définitivement supprimées'),
                  const Text('• Vos commandes payées sont conservées (anonymisées)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              '6. Délai de traitement',
              'La suppression ou l\'anonymisation de vos données est immédiate. Cependant :\n\n'
              '• Les sauvegardes techniques peuvent être conservées jusqu\'à 30 jours\n'
              '• Les données nécessaires pour des obligations légales peuvent être conservées\n'
              '• Les commandes payées anonymisées sont conservées pour raisons comptables',
            ),

            _buildSection(
              '7. Besoin d\'aide ?',
              'Si vous avez des questions ou besoin d\'assistance pour supprimer vos données, contactez-nous :',
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text('Email : privacy@vegnbio.com'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text('Téléphone : [Votre numéro]'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton d'accès rapide
            if (true) // TODO: Vérifier si l'utilisateur est connecté
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/account-deletion');
                  },
                  icon: const Icon(Icons.shield),
                  label: const Text('Accéder à la gestion de mes données'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            const SizedBox(height: 40),

            const Text(
              'Dernière mise à jour : 16 octobre 2024',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSubItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

