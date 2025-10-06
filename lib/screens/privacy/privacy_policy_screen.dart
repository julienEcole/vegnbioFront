import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de Confidentialité'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Introduction',
              'VegNBio s\'engage à protéger votre vie privée. Cette politique de confidentialité explique comment nous collectons, utilisons et protégeons vos informations personnelles lorsque vous utilisez notre application mobile.',
            ),
            _buildSection(
              '2. Informations que nous collectons',
              'Nous collectons les informations suivantes :\n\n'
              '• Informations de compte (nom, adresse e-mail, numéro de téléphone)\n'
              '• Informations de commande (adresse de livraison, préférences alimentaires)\n'
              '• Informations de paiement (traitées par Stripe, nous ne stockons pas ces informations)\n'
              '• Données d\'utilisation (pages visitées, fonctionnalités utilisées)\n'
              '• Informations techniques (type d\'appareil, système d\'exploitation)\n'
              '• Données de localisation (uniquement avec votre permission pour la livraison)',
            ),
            _buildSection(
              '3. Comment nous utilisons vos informations',
              'Nous utilisons vos informations personnelles pour :\n\n'
              '• Fournir nos services (traitement des commandes, livraison, support client)\n'
              '• Améliorer l\'application (analyse des performances, correction des bugs)\n'
              '• Communication (vous informer des mises à jour, promotions)\n'
              '• Sécurité (prévenir la fraude et assurer la sécurité de nos services)\n'
              '• Conformité légale (respecter les obligations légales)',
            ),
            _buildSection(
              '4. Partage d\'informations',
              'Nous ne vendons jamais vos informations personnelles. Nous partageons vos informations uniquement dans les cas suivants :\n\n'
              '• Prestataires de services (Stripe pour les paiements, services de livraison)\n'
              '• Services d\'analyse (données anonymisées)\n'
              '• Obligations légales (si requis par la loi ou une autorité compétente)',
            ),
            _buildSection(
              '5. Sécurité des données',
              'Nous mettons en place des mesures de sécurité appropriées pour protéger vos informations :\n\n'
              '• Chiffrement de toutes les communications (HTTPS)\n'
              '• Accès restreint aux données\n'
              '• Audit régulier de nos systèmes de sécurité',
            ),
            _buildSection(
              '6. Conservation des données',
              'Nous conservons vos informations personnelles aussi longtemps que nécessaire pour fournir nos services, respecter nos obligations légales, résoudre les litiges et faire respecter nos accords.',
            ),
            _buildSection(
              '7. Vos droits',
              'Conformément au RGPD, vous avez le droit de :\n\n'
              '• Accès : demander une copie de vos données personnelles\n'
              '• Rectification : corriger des informations inexactes\n'
              '• Suppression : demander la suppression de vos données\n'
              '• Portabilité : recevoir vos données dans un format structuré\n'
              '• Opposition : vous opposer au traitement de vos données\n'
              '• Limitation : demander la limitation du traitement',
            ),
            
            // Bouton vers la page de suppression de compte
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: Colors.red[700], size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Supprimer mon compte ou mes données',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pour exercer votre droit à l\'effacement (droit à l\'oubli), consultez notre page dédiée.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go('/data-deletion-info');
                      },
                      icon: Icon(Icons.arrow_forward, color: Colors.red[700]),
                      label: Text(
                        'Comment supprimer mon compte ?',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSection(
              '8. Cookies et technologies de suivi',
              'Nous utilisons des cookies pour améliorer votre expérience utilisateur :\n\n'
              '• Cookies essentiels (nécessaires au fonctionnement)\n'
              '• Cookies de performance (pour analyser l\'utilisation)\n'
              '• Cookies de fonctionnalité (pour mémoriser vos préférences)\n\n'
              'Vous pouvez gérer vos préférences de cookies dans les paramètres de votre appareil.',
            ),
            _buildSection(
              '9. Transferts internationaux',
              'Vos données peuvent être transférées vers des pays en dehors de l\'Union européenne. Dans ce cas, nous nous assurons que des garanties appropriées sont en place pour protéger vos données.',
            ),
            _buildSection(
              '10. Modifications de cette politique',
              'Nous pouvons mettre à jour cette politique de confidentialité. Les modifications importantes vous seront notifiées via l\'application ou par e-mail.',
            ),
            _buildSection(
              '11. Contact',
              'Pour toute question concernant cette politique de confidentialité ou vos données personnelles, contactez-nous :\n\n'
              '• E-mail : privacy@vegnbio.com\n'
              '• Adresse : [Votre adresse]\n'
              '• Téléphone : [Votre numéro]',
            ),
            _buildSection(
              '12. Autorité de contrôle',
              'Si vous n\'êtes pas satisfait de notre réponse à vos préoccupations, vous pouvez contacter l\'autorité de contrôle compétente dans votre pays.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note importante : Cette politique de confidentialité s\'applique uniquement à notre application mobile VegNBio. Elle ne couvre pas les pratiques de confidentialité des sites web ou services tiers que vous pourriez consulter via notre application.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dernière mise à jour : 3 octobre 2025',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
