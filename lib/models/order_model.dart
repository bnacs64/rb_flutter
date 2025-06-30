/// Custom exception for order model errors
class OrderModelException implements Exception {
  final String message;
  final String? field;

  OrderModelException(this.message, {this.field});

  @override
  String toString() =>
      'OrderModelException: $message${field != null ? ' (field: $field)' : ''}';
}

/// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  refunded;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        throw OrderModelException('Unknown order status: $status');
    }
  }
}

/// Payment method enum
enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  cashOnDelivery;

  String get displayName {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }

  static PaymentMethod fromString(String method) {
    switch (method.toLowerCase()) {
      case 'credit_card':
        return PaymentMethod.creditCard;
      case 'debit_card':
        return PaymentMethod.debitCard;
      case 'paypal':
        return PaymentMethod.paypal;
      case 'apple_pay':
        return PaymentMethod.applePay;
      case 'google_pay':
        return PaymentMethod.googlePay;
      case 'cash_on_delivery':
        return PaymentMethod.cashOnDelivery;
      default:
        throw OrderModelException('Unknown payment method: $method');
    }
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        throw OrderModelException('Unknown payment status: $status');
    }
  }
}

/// Order item model
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productImage;
  final String brand;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.brand,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString();
      if (id == null || id.isEmpty) {
        throw OrderModelException('Order item ID is required', field: 'id');
      }

      final productName = json['product_name']?.toString();
      if (productName == null || productName.isEmpty) {
        throw OrderModelException('Product name is required',
            field: 'product_name');
      }

      return OrderItem(
        id: id,
        orderId: json['order_id']?.toString() ?? '',
        productId: json['product_id']?.toString() ?? '',
        productName: productName,
        productImage: json['product_image']?.toString(),
        brand: json['brand']?.toString() ?? '',
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      if (e is OrderModelException) rethrow;
      throw OrderModelException('Failed to parse order item JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'brand': brand,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }
}

/// Delivery address model
class DeliveryAddress {
  final String id;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String postalCode;
  final double? latitude;
  final double? longitude;

  DeliveryAddress({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine1: json['address_line_1']?.toString() ?? '',
      addressLine2: json['address_line_2']?.toString(),
      city: json['city']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get fullAddress {
    final parts = [addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.addAll([city, postalCode]);
    return parts.join(', ');
  }
}

/// Delivery time slot model
class DeliveryTimeSlot {
  final String id;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  DeliveryTimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory DeliveryTimeSlot.fromJson(Map<String, dynamic> json) {
    return DeliveryTimeSlot(
      id: json['id']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isAvailable: json['is_available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    };
  }

  String get displayTime => '$startTime - $endTime';
}

/// Main Order model
class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final double subtotal;
  final double taxAmount;
  final double deliveryFee;
  final double discountAmount;
  final double totalAmount;
  final DeliveryAddress deliveryAddress;
  final String deliveryZone;
  final DeliveryTimeSlot deliverySlot;
  final DateTime scheduledDeliveryDate;
  final String? specialInstructions;
  final String? promotionId;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.taxAmount,
    required this.deliveryFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.deliveryZone,
    required this.deliverySlot,
    required this.scheduledDeliveryDate,
    this.specialInstructions,
    this.promotionId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString();
      if (id == null || id.isEmpty) {
        throw OrderModelException('Order ID is required', field: 'id');
      }

      final orderNumber = json['order_number']?.toString();
      if (orderNumber == null || orderNumber.isEmpty) {
        throw OrderModelException('Order number is required',
            field: 'order_number');
      }

      // Parse delivery address
      DeliveryAddress deliveryAddress;
      if (json['delivery_address'] != null) {
        deliveryAddress = DeliveryAddress.fromJson(json['delivery_address']);
      } else {
        throw OrderModelException('Delivery address is required',
            field: 'delivery_address');
      }

      // Parse delivery slot
      DeliveryTimeSlot deliverySlot;
      if (json['delivery_slot'] != null) {
        deliverySlot = DeliveryTimeSlot.fromJson(json['delivery_slot']);
      } else {
        throw OrderModelException('Delivery slot is required',
            field: 'delivery_slot');
      }

      // Parse order items
      List<OrderItem> items = [];
      if (json['items'] != null && json['items'] is List) {
        items = (json['items'] as List)
            .map((item) => OrderItem.fromJson(item))
            .toList();
      }

      return Order(
        id: id,
        orderNumber: orderNumber,
        userId: json['user_id']?.toString() ?? '',
        status: OrderStatus.fromString(json['status']?.toString() ?? 'pending'),
        paymentMethod: PaymentMethod.fromString(
            json['payment_method']?.toString() ?? 'credit_card'),
        paymentStatus: PaymentStatus.fromString(
            json['payment_status']?.toString() ?? 'pending'),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
        deliveryAddress: deliveryAddress,
        deliveryZone: json['delivery_zone']?.toString() ?? '',
        deliverySlot: deliverySlot,
        scheduledDeliveryDate: _parseDateTime(json['scheduled_delivery_date']),
        specialInstructions: json['special_instructions']?.toString(),
        promotionId: json['promotion_id']?.toString(),
        items: items,
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
    } catch (e) {
      if (e is OrderModelException) rethrow;
      throw OrderModelException('Failed to parse order JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user_id': userId,
      'status': status.name,
      'payment_method': paymentMethod.name,
      'payment_status': paymentStatus.name,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'delivery_fee': deliveryFee,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress.toJson(),
      'delivery_zone': deliveryZone,
      'delivery_slot': deliverySlot.toJson(),
      'scheduled_delivery_date': scheduledDeliveryDate.toIso8601String(),
      'special_instructions': specialInstructions,
      'promotion_id': promotionId,
      'items': items.map((item) => item.toJson()).toList(),
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

  /// Check if order can be cancelled
  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  /// Check if order is active (not cancelled, delivered, or refunded)
  bool get isActive {
    return status != OrderStatus.cancelled &&
        status != OrderStatus.delivered &&
        status != OrderStatus.refunded;
  }

  /// Get total number of items in the order
  int get totalItems {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  /// Get estimated delivery date range
  String get estimatedDeliveryTime {
    return '${scheduledDeliveryDate.day}/${scheduledDeliveryDate.month}/${scheduledDeliveryDate.year} ${deliverySlot.displayTime}';
  }

  /// Create a copy of the order with updated fields
  Order copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    double? subtotal,
    double? taxAmount,
    double? deliveryFee,
    double? discountAmount,
    double? totalAmount,
    DeliveryAddress? deliveryAddress,
    String? deliveryZone,
    DeliveryTimeSlot? deliverySlot,
    DateTime? scheduledDeliveryDate,
    String? specialInstructions,
    String? promotionId,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryZone: deliveryZone ?? this.deliveryZone,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      scheduledDeliveryDate:
          scheduledDeliveryDate ?? this.scheduledDeliveryDate,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      promotionId: promotionId ?? this.promotionId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
