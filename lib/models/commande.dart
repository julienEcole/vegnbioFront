import 'commande_item.dart';

enum CommandeStatut {
  draft('draft'),
  pending('pending'),
  paid('paid'),
  cancelled('cancelled'),
  refunded('refunded');

  const CommandeStatut(this.value);
  final String value;

  static CommandeStatut fromString(String value) {
    return CommandeStatut.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CommandeStatut.draft,
    );
  }

  String get displayName {
    switch (this) {
      case CommandeStatut.draft:
        return 'Brouillon';
      case CommandeStatut.pending:
        return 'En attente';
      case CommandeStatut.paid:
        return 'Payée';
      case CommandeStatut.cancelled:
        return 'Annulée';
      case CommandeStatut.refunded:
        return 'Remboursée';
    }
  }
}

class Commande {
  final int id;
  final int restaurantId;
  final CommandeStatut statut;
  final String currency;
  final double totalHT;
  final double totalTVA;
  final double totalTTC;
  final double tvaRate;
  final List<CommandeItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Commande({
    required this.id,
    required this.restaurantId,
    required this.statut,
    required this.currency,
    required this.totalHT,
    required this.totalTVA,
    required this.totalTTC,
    required this.tvaRate,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      statut: CommandeStatut.fromString(json['statut']),
      currency: json['currency'] ?? 'EUR',
      totalHT: (json['totalHT'] ?? 0).toDouble(),
      totalTVA: (json['totalTVA'] ?? 0).toDouble(),
      totalTTC: (json['totalTTC'] ?? 0).toDouble(),
      tvaRate: (json['tvaRate'] ?? 10).toDouble(),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CommandeItem.fromJson(item))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'statut': statut.value,
      'currency': currency,
      'totalHT': totalHT,
      'totalTVA': totalTVA,
      'totalTTC': totalTTC,
      'tvaRate': tvaRate,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Méthodes utilitaires
  String get prixText => '${totalTTC.toStringAsFixed(2)} €';
  String get prixHTText => '${totalHT.toStringAsFixed(2)} €';
  String get tvaText => '${totalTVA.toStringAsFixed(2)} €';
  int get nombreItems => items.fold(0, (sum, item) => sum + item.quantite);
  
  bool get isDraft => statut == CommandeStatut.draft;
  bool get isPending => statut == CommandeStatut.pending;
  bool get isPaid => statut == CommandeStatut.paid;
  bool get isCancelled => statut == CommandeStatut.cancelled;
  bool get isRefunded => statut == CommandeStatut.refunded;
}
