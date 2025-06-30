/// User profile model that matches Supabase database schema
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final DateTime? dateOfBirth;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.dateOfBirth,
    this.role = 'customer',
    this.avatarUrl,
    this.isActive = true,
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      role: json['role'] ?? 'customer',
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'role': role,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is customer
  bool get isCustomer => role == 'customer';

  /// Get display name
  String get displayName => fullName ?? email.split('@').first;
}

/// Customer address model
class CustomerAddress {
  final String id;
  final String userId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? landmark;
  final bool isDefault;
  final String addressType;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerAddress({
    required this.id,
    required this.userId,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.landmark,
    this.isDefault = false,
    this.addressType = 'home',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      landmark: json['landmark'],
      isDefault: json['is_default'] ?? false,
      addressType: json['address_type'] ?? 'home',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'landmark': landmark,
      'is_default': isDefault,
      'address_type': addressType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted address
  String get formattedAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }
}
