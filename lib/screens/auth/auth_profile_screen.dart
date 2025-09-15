import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/simple_auth_provider.dart';

/// Écran de profil utilisateur
class AuthProfileScreen extends ConsumerStatefulWidget {
  const AuthProfileScreen({super.key});

  @override
  ConsumerState<AuthProfileScreen> createState() => _AuthProfileScreenState();
}

class _AuthProfileScreenState extends ConsumerState<AuthProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = ref.read(simpleAuthProvider);
    if (authState.userData != null) {
      _nomController.text = authState.userData!['nom'] ?? '';
      _prenomController.text = authState.userData!['prenom'] ?? '';
      _telephoneController.text = authState.userData!['telephone'] ?? '';
    }
  }

  Future<void> _handleUpdateProfile() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(simpleAuthProvider.notifier).updateProfile(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty 
            ? null 
            : _telephoneController.text.trim(),
      );
      
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(simpleAuthProvider.notifier).changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      if (success) {
        setState(() {
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe modifié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(simpleAuthProvider.notifier).logout();
      if (mounted) {
        Navigator.pop(context); // Retourner à l'écran précédent
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(simpleAuthProvider);
    final userData = authState.userData;
    
    if (userData == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          if (!_isEditing && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'Déconnexion',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar et informations principales
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        '${userData['prenom']?[0] ?? ''}${userData['nom']?[0] ?? ''}'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userData['email'] ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Informations personnelles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Informations personnelles',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isEditing && !_isChangingPassword)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ prénom
                      TextFormField(
                        controller: _prenomController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          prefixIcon: Icon(Icons.person_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_isEditing && (value == null || value.isEmpty)) {
                            return 'Prénom requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ nom
                      TextFormField(
                        controller: _nomController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_isEditing && (value == null || value.isEmpty)) {
                            return 'Nom requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ téléphone
                      TextFormField(
                        controller: _telephoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      // Boutons d'édition
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _loadUserData(); // Restaurer les valeurs
                                  });
                                },
                                child: const Text('Annuler'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleUpdateProfile,
                                child: const Text('Sauvegarder'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Changement de mot de passe
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mot de passe',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isEditing && !_isChangingPassword)
                            IconButton(
                              icon: const Icon(Icons.lock),
                              onPressed: () {
                                setState(() {
                                  _isChangingPassword = true;
                                });
                              },
                            ),
                        ],
                      ),
                      
                      if (_isChangingPassword) ...[
                        const SizedBox(height: 16),
                        
                        // Mot de passe actuel
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe actuel',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrentPassword = !_obscureCurrentPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mot de passe actuel requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Nouveau mot de passe
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nouveau mot de passe requis';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirmation nouveau mot de passe
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le nouveau mot de passe',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirmation requise';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Boutons changement mot de passe
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isChangingPassword = false;
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  });
                                },
                                child: const Text('Annuler'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleChangePassword,
                                child: const Text('Changer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Message d'erreur
              if (authState.hasError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
