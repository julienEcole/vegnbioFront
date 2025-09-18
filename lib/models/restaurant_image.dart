// Modèle pour les images de restaurant
class RestaurantImage {
  final int id;
  final int restaurantId;
  final String imageUrl;
  final String? description;
  final int ordre;
  final bool isPrimary;

  RestaurantImage({
    required this.id,
    required this.restaurantId,
    required this.imageUrl,
    this.description,
    required this.ordre,
    required this.isPrimary,
  });

  factory RestaurantImage.fromJson(Map<String, dynamic> json) {
    return RestaurantImage(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      restaurantId: json['restaurant_id'] is int ? json['restaurant_id'] : int.tryParse(json['restaurant_id'].toString()) ?? 0,
      imageUrl: json['imageUrl'] ?? json['image_url']?.toString() ?? '',
      description: json['description']?.toString(),
      ordre: json['ordre'] is int ? json['ordre'] : int.tryParse(json['ordre'].toString()) ?? 1,
      isPrimary: json['isPrimary'] is bool ? json['isPrimary'] : json['is_primary'] == 'true' || json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'image_url': imageUrl,
      'description': description,
      'ordre': ordre,
      'is_primary': isPrimary,
    };
  }
}
