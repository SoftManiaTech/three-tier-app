class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String? createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: (json['category']?.toString() ?? 'General').trim().isEmpty
          ? 'General'
          : json['category'].toString().trim(),
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ??
          json['createdAt']?.toString() ??
          json['created_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'name': name.trim(),
      'category': category.trim().isEmpty ? 'General' : category.trim(),
      'price': price,
      'description': description.trim(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? description,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
