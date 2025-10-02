class Commande {
  final int id;
  final int restaurantId;
  final int? userId;
  final String statut;
  final String currency;
  final double totalHT;
  final double totalTVA;
  final double totalTTC;
  final double tvaRate;
  final List<CommandeItem> items;
  final PaymentInfo? paymentInfo;
  final DeliveryInfo? deliveryInfo;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? preparedAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final DateTime? lastStatusChangeAt;

  Commande({
    required this.id,
    required this.restaurantId,
    this.userId,
    required this.statut,
    required this.currency,
    required this.totalHT,
    required this.totalTVA,
    required this.totalTTC,
    required this.tvaRate,
    required this.items,
    this.paymentInfo,
    this.deliveryInfo,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.preparedAt,
    this.readyAt,
    this.deliveredAt,
    this.cancelledAt,
    this.refundedAt,
    this.lastStatusChangeAt,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'],
      restaurantId: json['restaurantId'],
      userId: json['userId'],
      statut: json['statut'],
      currency: json['currency'],
      totalHT: _parseDouble(json['totalHT']),
      totalTVA: _parseDouble(json['totalTVA']),
      totalTTC: _parseDouble(json['totalTTC']),
      tvaRate: _parseDouble(json['tvaRate'] ?? 10),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CommandeItem.fromJson(item))
          .toList() ?? [],
      paymentInfo: json['paymentInfo'] != null 
          ? PaymentInfo.fromJson(json['paymentInfo']) 
          : null,
      deliveryInfo: json['deliveryInfo'] != null 
          ? DeliveryInfo.fromJson(json['deliveryInfo']) 
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.parse(json['confirmedAt']) 
          : null,
      preparedAt: json['preparedAt'] != null 
          ? DateTime.parse(json['preparedAt']) 
          : null,
      readyAt: json['readyAt'] != null 
          ? DateTime.parse(json['readyAt']) 
          : null,
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.parse(json['deliveredAt']) 
          : null,
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt']) 
          : null,
      refundedAt: json['refundedAt'] != null 
          ? DateTime.parse(json['refundedAt']) 
          : null,
      lastStatusChangeAt: json['lastStatusChangeAt'] != null 
          ? DateTime.parse(json['lastStatusChangeAt']) 
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'userId': userId,
      'statut': statut,
      'currency': currency,
      'totalHT': totalHT,
      'totalTVA': totalTVA,
      'totalTTC': totalTTC,
      'tvaRate': tvaRate,
      'items': items.map((item) => item.toJson()).toList(),
      'paymentInfo': paymentInfo?.toJson(),
      'deliveryInfo': deliveryInfo?.toJson(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'preparedAt': preparedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
      'lastStatusChangeAt': lastStatusChangeAt?.toIso8601String(),
    };
  }

  bool get isPaid => ['paid', 'confirmed', 'preparing', 'ready', 'delivered'].contains(statut);
  
  bool get canBeCancelled => ['pending', 'paid', 'confirmed'].contains(statut);
  
  bool get canBeRefunded => isPaid && statut != 'refunded';

  String get statusDisplayName {
    switch (statut) {
      case 'draft': return 'Brouillon';
      case 'pending': return 'En attente de paiement';
      case 'paid': return 'Payée';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'ready': return 'Prête';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      case 'refunded': return 'Remboursée';
      case 'payment_failed': return 'Paiement échoué';
      case 'suspicious': return 'Suspecte';
      case 'to_pay_restaurant': return 'À payer au restaurant';
      default: return statut;
    }
  }

  String get statusColor {
    switch (statut) {
      case 'draft': return '#9E9E9E';
      case 'pending': return '#FF9800';
      case 'paid': return '#4CAF50';
      case 'confirmed': return '#2196F3';
      case 'preparing': return '#FF5722';
      case 'ready': return '#8BC34A';
      case 'delivered': return '#4CAF50';
      case 'cancelled': return '#F44336';
      case 'refunded': return '#9C27B0';
      case 'payment_failed': return '#F44336';
      case 'suspicious': return '#E91E63';
      case 'to_pay_restaurant': return '#FF9800';
      default: return '#9E9E9E';
    }
  }
}

class CommandeItem {
  final int id;
  final int commandeId;
  final int? menuId;
  final String nom;
  final double prixUnitaire;
  final int quantite;
  final double totalLigne;

  CommandeItem({
    required this.id,
    required this.commandeId,
    this.menuId,
    required this.nom,
    required this.prixUnitaire,
    required this.quantite,
    required this.totalLigne,
  });

  factory CommandeItem.fromJson(Map<String, dynamic> json) {
    return CommandeItem(
      id: json['id'],
      commandeId: json['commandeId'],
      menuId: json['menuId'],
      nom: json['nom'],
      prixUnitaire: _parseDouble(json['prixUnitaire']),
      quantite: json['quantite'] ?? 1,
      totalLigne: _parseDouble(json['totalLigne']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commandeId': commandeId,
      'menuId': menuId,
      'nom': nom,
      'prixUnitaire': prixUnitaire,
      'quantite': quantite,
      'totalLigne': totalLigne,
    };
  }
}

class PaymentInfo {
  final String? paymentIntentId;
  final String? paymentMethodId;
  final int? amount;
  final String? currency;
  final String? status;
  final String? cardBrand;
  final String? cardLast4;
  final DateTime? paidAt;

  PaymentInfo({
    this.paymentIntentId,
    this.paymentMethodId,
    this.amount,
    this.currency,
    this.status,
    this.cardBrand,
    this.cardLast4,
    this.paidAt,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      paymentIntentId: json['paymentIntentId'],
      paymentMethodId: json['paymentMethodId'],
      amount: json['amount'],
      currency: json['currency'],
      status: json['status'],
      cardBrand: json['cardBrand'],
      cardLast4: json['cardLast4'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentIntentId': paymentIntentId,
      'paymentMethodId': paymentMethodId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'cardBrand': cardBrand,
      'cardLast4': cardLast4,
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  String get cardDisplay => cardBrand != null && cardLast4 != null 
      ? '${cardBrand!.toUpperCase()} **** $cardLast4' 
      : 'Carte non disponible';
}

class DeliveryInfo {
  final String type;
  final String? address;
  final String? phone;
  final DateTime? estimatedTime;
  final DateTime? deliveredAt;

  DeliveryInfo({
    required this.type,
    this.address,
    this.phone,
    this.estimatedTime,
    this.deliveredAt,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      type: json['type'] ?? 'pickup',
      address: json['address'],
      phone: json['phone'],
      estimatedTime: json['estimatedTime'] != null 
          ? DateTime.parse(json['estimatedTime']) 
          : null,
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.parse(json['deliveredAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'address': address,
      'phone': phone,
      'estimatedTime': estimatedTime?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  String get typeDisplay => type == 'pickup' ? 'À emporter' : 'Livraison';
}
