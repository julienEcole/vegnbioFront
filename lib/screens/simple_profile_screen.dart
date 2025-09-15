import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simple_auth_provider.dart';
import '../widgets/navigation_bar.dart';

class SimpleProfileScreen extends ConsumerStatefulWidget {
  const SimpleProfileScreen({super.key});

  @override
  ConsumerState<SimpleProfileScreen> createState() => _SimpleProfileScreenState();
}

class _SimpleProfileScreenState extends ConsumerState<SimpleProfileScreen> {
  // Controllers pour la connexion
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Controllers pour l'inscription
  final _registerNomController = TextEditingController();
  final _registerPrenomController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  // Controllers pour le profil
  final _profileNomController = TextEditingController();
  final _profilePrenomController = TextEditingController();
  final _profileEmailController = TextEditingController();

  String _selectedRegisterRole = 'client';

  @override
  void initState() {
    super.initState();
    print('🚨 [SimpleProfileScreen] initState - Initialisation');
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNomController.dispose();
    _registerPrenomController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _profileNomController.dispose();
    _profilePrenomController.dispose();
    _profileEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(simpleAuthProvider);
    
    print('🎨 [SimpleProfileScreen] build - AuthState: ${authState.status}');
    print('🎨 [SimpleProfileScreen] build - Role: ${authState.role}');
    print('🎨 [SimpleProfileScreen] build - UserData: ${authState.userData}');

    // Mettre à jour les controllers avec les données utilisateur si connecté
    if (authState.isAuthenticated && authState.userData != null) {
      _updateProfileControllers(authState.userData!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(authState.isAuthenticated ? 'Mon Profil' : 'Connexion'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(authState),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: 5, // Index du profil
        onDestinationSelected: (index) {
          // Navigation gérée par le parent ou un service de navigation global
          print('🔍 [SimpleProfileScreen] Navigation vers index: $index');
        },
      ),
    );
  }

  Widget _buildBody(SimpleAuthState authState) {
    if (authState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement...'),
          ],
        ),
      );
    }

    if (authState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Erreur: ${authState.errorMessage}',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Relancer la vérification d'authentification
                ref.read(simpleAuthProvider.notifier).checkAuthStatus();
              },
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (authState.isAuthenticated) {
      return _buildAuthenticatedView(authState);
    } else {
      return _buildUnauthenticatedView();
    }
  }

  Widget _buildAuthenticatedView(SimpleAuthState authState) {
    print('👤 [SimpleProfileScreen] _buildAuthenticatedView - UserData: ${authState.userData}');

    final userData = authState.userData!;
    final role = authState.role ?? 'client';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge du rôle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor(role),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleDisplayName(role),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Informations du profil
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations personnelles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _profileNomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _profilePrenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _profileEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Sauvegarder'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Informations du compte
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations du compte',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text('Rôle'),
                    subtitle: Text(_getRoleDisplayName(role)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getRoleColor(role)),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          color: _getRoleColor(role),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Membre depuis'),
                    subtitle: Text(_formatDate(userData['dateCreation'])),
                  ),
                  ListTile(
                    leading: const Icon(Icons.fingerprint),
                    title: const Text('ID Utilisateur'),
                    subtitle: Text('#${userData['id']}'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Actualiser le profil'),
                    onTap: () {
                      ref.read(simpleAuthProvider.notifier).checkAuthStatus();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Colors.grey),
          const SizedBox(height: 32),
          const Text(
            'Bienvenue sur Veg\'N Bio',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Connectez-vous ou créez un compte pour accéder à toutes les fonctionnalités',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _showLoginDialog(context),
              icon: const Icon(Icons.login),
              label: const Text('Se connecter', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _showRegisterDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Créer un compte', style: TextStyle(fontSize: 18)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateProfileControllers(Map<String, dynamic> userData) {
    if (_profileNomController.text != (userData['nom'] ?? '')) {
      _profileNomController.text = userData['nom'] ?? '';
    }
    if (_profilePrenomController.text != (userData['prenom'] ?? '')) {
      _profilePrenomController.text = userData['prenom'] ?? '';
    }
    if (_profileEmailController.text != (userData['email'] ?? '')) {
      _profileEmailController.text = userData['email'] ?? '';
    }
  }

  Future<void> _showLoginDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se connecter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _loginEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _loginPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comptes de test :', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Client: client@vegnbio.test / test'),
                  Text('Admin: admin@vegnbio.test / test'),
                  Text('Restaurateur: restaurateur@vegnbio.test / test'),
                  Text('Fournisseur: fournisseur@vegnbio.test / test'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _login();
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRegisterDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Créer un compte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _registerNomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _registerPrenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _registerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _registerPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe (min. 8 caractères)',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRegisterRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'client', child: Text('Client')),
                    DropdownMenuItem(value: 'restaurateur', child: Text('Restaurateur')),
                    DropdownMenuItem(value: 'fournisseur', child: Text('Fournisseur')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRegisterRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _register();
              },
              child: const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Veuillez remplir tous les champs', Colors.red);
      return;
    }

    print('🔐 [SimpleProfileScreen] Tentative de connexion pour: $email');

    final success = await ref.read(simpleAuthProvider.notifier).login(email, password);

    if (success) {
      _showMessage('Connexion réussie !', Colors.green);
      _loginEmailController.clear();
      _loginPasswordController.clear();
    } else {
      final authState = ref.read(simpleAuthProvider);
      _showMessage(authState.errorMessage ?? 'Erreur de connexion', Colors.red);
    }
  }

  Future<void> _register() async {
    final nom = _registerNomController.text.trim();
    final prenom = _registerPrenomController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();

    if (nom.isEmpty || prenom.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Veuillez remplir tous les champs', Colors.red);
      return;
    }

    if (password.length < 8) {
      _showMessage('Le mot de passe doit contenir au moins 8 caractères', Colors.red);
      return;
    }

    print('📝 [SimpleProfileScreen] Tentative d\'inscription pour: $email avec rôle: $_selectedRegisterRole');

    final success = await ref.read(simpleAuthProvider.notifier).register(
      nom: nom,
      prenom: prenom,
      email: email,
      motDePasse: password,
      nameRole: _selectedRegisterRole,
    );

    if (success) {
      _showMessage('Compte créé avec succès !', Colors.green);
      _registerNomController.clear();
      _registerPrenomController.clear();
      _registerEmailController.clear();
      _registerPasswordController.clear();
    } else {
      final authState = ref.read(simpleAuthProvider);
      _showMessage(authState.errorMessage ?? 'Erreur d\'inscription', Colors.red);
    }
  }

  Future<void> _logout() async {
    await ref.read(simpleAuthProvider.notifier).logout();
    _showMessage('Déconnexion réussie', Colors.green);
  }

  Future<void> _updateProfile() async {
    _showMessage('Fonctionnalité de mise à jour du profil non implémentée', Colors.orange);
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'restaurateur':
        return Colors.blue;
      case 'fournisseur':
        return Colors.green;
      case 'client':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'restaurateur':
        return 'Restaurateur';
      case 'fournisseur':
        return 'Fournisseur';
      case 'client':
        return 'Client';
      default:
        return 'Utilisateur';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Non disponible';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Non disponible';
    }
  }
}

