class User {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final DateTime dateCreation;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.dateCreation,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'client',
      dateCreation: json['dateCreation'] != null 
          ? DateTime.parse(json['dateCreation'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  String get fullName => '$prenom $nom';
  
  bool get isAdmin => role == 'admin';
  bool get isRestaurateur => role == 'restaurateur';
  bool get isFournisseur => role == 'fournisseur';
  bool get isClient => role == 'client';
}
