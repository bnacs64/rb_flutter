/// Custom exception for address model errors
class AddressModelException implements Exception {
  final String message;
  final String? field;

  AddressModelException(this.message, {this.field});

  @override
  String toString() => 'AddressModelException: $message${field != null ? ' (field: $field)' : ''}';
}

/// Delivery zone model
class DeliveryZone {
  final String id;
  final String name;
  final String? description;
  final double deliveryFee;
  final double minimumOrder;
  final int? estimatedDeliveryTime; // in minutes
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryZone({
    required this.id,
    required this.name,
    this.description,
    required this.deliveryFee,
    required this.minimumOrder,
    this.estimatedDeliveryTime,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString();
      if (id == null || id.isEmpty) {
        throw AddressModelException('Delivery zone ID is required', field: 'id');
      }

      final name = json['name']?.toString();
      if (name == null || name.isEmpty) {
        throw AddressModelException('Delivery zone name is required', field: 'name');
      }

      return DeliveryZone(
        id: id,
        name: name,
        description: json['description']?.toString(),
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        minimumOrder: (json['minimum_order'] as num?)?.toDouble() ?? 0.0,
        estimatedDeliveryTime: (json['estimated_delivery_time'] as num?)?.toInt(),
        isActive: json['is_active'] as bool? ?? true,
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
    } catch (e) {
      if (e is AddressModelException) rethrow;
      throw AddressModelException('Failed to parse delivery zone JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'delivery_fee': deliveryFee,
      'minimum_order': minimumOrder,
      'estimated_delivery_time': estimatedDeliveryTime,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helper method to parse DateTime safely
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Get formatted delivery fee
  String get formattedDeliveryFee => '\$${deliveryFee.toStringAsFixed(2)}';

  /// Get formatted minimum order
  String get formattedMinimumOrder => '\$${minimumOrder.toStringAsFixed(2)}';

  /// Get estimated delivery time display
  String get estimatedDeliveryDisplay {
    if (estimatedDeliveryTime == null) return 'Standard delivery';
    final hours = estimatedDeliveryTime! ~/ 60;
    final minutes = estimatedDeliveryTime! % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Create a copy with updated fields
  DeliveryZone copyWith({
    String? id,
    String? name,
    String? description,
    double? deliveryFee,
    double? minimumOrder,
    int? estimatedDeliveryTime,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryZone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Enhanced customer address model with additional fields
class CustomerAddress {
  final String id;
  final String userId;
  final String label; // 'Home', 'Work', etc.
  final String fullName;
  final String? phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String postalCode;
  final String? province;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? deliveryInstructions;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullName,
    this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.postalCode,
    this.province,
    required this.country,
    this.latitude,
    this.longitude,
    this.deliveryInstructions,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString();
      if (id == null || id.isEmpty) {
        throw AddressModelException('Address ID is required', field: 'id');
      }

      return CustomerAddress(
        id: id,
        userId: json['user_id']?.toString() ?? '',
        label: json['label']?.toString() ?? 'Address',
        fullName: json['full_name']?.toString() ?? '',
        phone: json['phone']?.toString(),
        addressLine1: json['address_line_1']?.toString() ?? '',
        addressLine2: json['address_line_2']?.toString(),
        city: json['city']?.toString() ?? '',
        postalCode: json['postal_code']?.toString() ?? '',
        province: json['province']?.toString(),
        country: json['country']?.toString() ?? 'Canada',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        deliveryInstructions: json['delivery_instructions']?.toString(),
        isDefault: json['is_default'] as bool? ?? false,
        createdAt: DeliveryZone._parseDateTime(json['created_at']),
        updatedAt: DeliveryZone._parseDateTime(json['updated_at']),
      );
    } catch (e) {
      if (e is AddressModelException) rethrow;
      throw AddressModelException('Failed to parse customer address JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'full_name': fullName,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      'province': province,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'delivery_instructions': deliveryInstructions,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get full formatted address
  String get fullAddress {
    final parts = <String>[addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.addAll([city, postalCode]);
    if (province != null && province!.isNotEmpty) {
      parts.add(province!);
    }
    parts.add(country);
    return parts.join(', ');
  }

  /// Get short address for display
  String get shortAddress {
    final parts = <String>[addressLine1, city];
    return parts.join(', ');
  }

  /// Check if address has coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Validate address data
  List<String> validate() {
    final errors = <String>[];

    if (fullName.isEmpty) {
      errors.add('Full name is required');
    }
    if (addressLine1.isEmpty) {
      errors.add('Address line 1 is required');
    }
    if (city.isEmpty) {
      errors.add('City is required');
    }
    if (postalCode.isEmpty) {
      errors.add('Postal code is required');
    }
    if (country.isEmpty) {
      errors.add('Country is required');
    }

    return errors;
  }

  /// Check if address is valid
  bool get isValid => validate().isEmpty;

  /// Create a copy with updated fields
  CustomerAddress copyWith({
    String? id,
    String? userId,
    String? label,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? province,
    String? country,
    double? latitude,
    double? longitude,
    String? deliveryInstructions,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      province: province ?? this.province,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
