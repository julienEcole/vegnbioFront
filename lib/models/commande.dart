import 'commande_item.dart';

enum CommandeStatut {
  draft,
  pending,
  paid,
  cancelled,
  refunded,
}

extension CommandeStatutExtension on CommandeStatut {
  String get value {
    switch (this) {
      case CommandeStatut.draft:
        return 'draft';
      case CommandeStatut.pending:
        return 'pending';
      case CommandeStatut.paid:
        return 'paid';
      case CommandeStatut.cancelled:
        return 'cancelled';
      case CommandeStatut.refunded:
        return 'refunded';
    }
  }

  static CommandeStatut fromString(String value) {
    switch (value) {
      case 'draft':
        return CommandeStatut.draft;
      case 'pending':
        return CommandeStatut.pending;
      case 'paid':
        return CommandeStatut.paid;
      case 'cancelled':
        return CommandeStatut.cancelled;
      case 'refunded':
        return CommandeStatut.refunded;
      default:
        return CommandeStatut.draft;
    }
  }
}

class Commande {
  final int? id;
  final int restaurantId;
  final CommandeStatut statut;
  final String currency;
  final double totalHT;
  final double totalTVA;
  final double totalTTC;
  final double tvaRate;
  final List<CommandeItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Commande({
    this.id,
    required this.restaurantId,
    required this.statut,
    required this.currency,
    required this.totalHT,
    required this.totalTVA,
    required this.totalTTC,
    required this.tvaRate,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'],
      restaurantId: json['restaurantId'] ?? json['restaurant_id'] ?? 0,
      statut: CommandeStatutExtension.fromString(json['statut'] ?? 'draft'),
      currency: json['currency'] ?? 'EUR',
      totalHT: _parseDouble(json['totalHT'] ?? json['total_ht'] ?? 0),
      totalTVA: _parseDouble(json['totalTVA'] ?? json['total_tva'] ?? 0),
      totalTTC: _parseDouble(json['totalTTC'] ?? json['total_ttc'] ?? 0),
      tvaRate: _parseDouble(json['tvaRate'] ?? json['tva_rate'] ?? 20),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CommandeItem.fromJson(item))
          .toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'statut': statut.value,
      'currency': currency,
      'totalHT': totalHT,
      'totalTVA': totalTVA,
      'totalTTC': totalTTC,
      'tvaRate': tvaRate,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Commande copyWith({
    int? id,
    int? restaurantId,
    CommandeStatut? statut,
    String? currency,
    double? totalHT,
    double? totalTVA,
    double? totalTTC,
    double? tvaRate,
    List<CommandeItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Commande(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      statut: statut ?? this.statut,
      currency: currency ?? this.currency,
      totalHT: totalHT ?? this.totalHT,
      totalTVA: totalTVA ?? this.totalTVA,
      totalTTC: totalTTC ?? this.totalTTC,
      tvaRate: tvaRate ?? this.tvaRate,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Commande(id: $id, restaurantId: $restaurantId, statut: ${statut.value}, currency: $currency, totalHT: $totalHT, totalTVA: $totalTVA, totalTTC: $totalTTC, tvaRate: $tvaRate, items: ${items.length} items)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Commande &&
        other.id == id &&
        other.restaurantId == restaurantId &&
        other.statut == statut &&
        other.currency == currency &&
        other.totalHT == totalHT &&
        other.totalTVA == totalTVA &&
        other.totalTTC == totalTTC &&
        other.tvaRate == tvaRate &&
        other.items.length == items.length;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        restaurantId.hashCode ^
        statut.hashCode ^
        currency.hashCode ^
        totalHT.hashCode ^
        totalTVA.hashCode ^
        totalTTC.hashCode ^
        tvaRate.hashCode ^
        items.length.hashCode;
  }
}
