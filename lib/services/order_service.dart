import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/order_model.dart';

/// Custom exception for order service errors
class OrderServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  OrderServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'OrderServiceException: $message';
}

/// Service for managing orders
class OrderService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Create order from current cart
  Future<String> createOrderFromCart({
    required String deliveryAddressId,
    required String deliveryZoneId,
    required String deliverySlotId,
    required DateTime scheduledDeliveryDate,
    required PaymentMethod paymentMethod,
    String? specialInstructions,
    String? promotionId,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw OrderServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      if (deliveryAddressId.isEmpty) {
        throw OrderServiceException('Delivery address ID is required', code: 'INVALID_ADDRESS');
      }

      if (deliveryZoneId.isEmpty) {
        throw OrderServiceException('Delivery zone ID is required', code: 'INVALID_ZONE');
      }

      if (deliverySlotId.isEmpty) {
        throw OrderServiceException('Delivery slot ID is required', code: 'INVALID_SLOT');
      }

      final response = await _client.rpc('create_order_from_cart', params: {
        'user_id_param': userId,
        'delivery_address_id_param': deliveryAddressId,
        'delivery_zone_id_param': deliveryZoneId,
        'delivery_slot_id_param': deliverySlotId,
        'scheduled_delivery_date_param': scheduledDeliveryDate.toIso8601String().split('T')[0],
        'payment_method_param': _paymentMethodToString(paymentMethod),
        'special_instructions_param': specialInstructions,
        'promotion_id_param': promotionId,
      });

      if (response == null || response['success'] != true) {
        throw OrderServiceException(
          response?['message'] ?? 'Failed to create order',
          code: 'ORDER_CREATION_FAILED',
        );
      }

      final orderId = response['order_id'];
      if (orderId == null) {
        throw OrderServiceException('Order ID not returned', code: 'MISSING_ORDER_ID');
      }

      return orderId.toString();
    } on PostgrestException catch (e) {
      throw OrderServiceException(
        'Database error while creating order: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      throw OrderServiceException(
        'Failed to create order: $e',
        originalError: e,
      );
    }
  }

  /// Get user's order history
  Future<List<Order>> getUserOrders({
    int limit = 20,
    int offset = 0,
    OrderStatus? statusFilter,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw OrderServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      if (limit <= 0 || limit > 100) {
        throw OrderServiceException('Limit must be between 1 and 100', code: 'INVALID_LIMIT');
      }

      if (offset < 0) {
        throw OrderServiceException('Offset must be non-negative', code: 'INVALID_OFFSET');
      }

      var query = _client
          .from(SupabaseTables.orders)
          .select('''
            *,
            order_items (
              *,
              products (name, images, brand)
            ),
            customer_addresses!delivery_address_id (
              id, full_name, phone, address_line_1, address_line_2, 
              city, postal_code, latitude, longitude
            ),
            delivery_zones!delivery_zone_id (name),
            delivery_time_slots!delivery_slot_id (id, start_time, end_time, is_available)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.name);
      }

      final response = await query;

      return response.map<Order>((json) => _parseOrderFromTableResponse(json)).toList();
    } on PostgrestException catch (e) {
      throw OrderServiceException(
        'Database error while fetching orders: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      throw OrderServiceException(
        'Failed to fetch user orders: $e',
        originalError: e,
      );
    }
  }

  /// Get detailed order information
  Future<Order> getOrderDetails(String orderId) async {
    try {
      if (orderId.isEmpty) {
        throw OrderServiceException('Order ID is required', code: 'INVALID_ORDER_ID');
      }

      final response = await _client.rpc('get_order_details', params: {
        'order_id_param': orderId,
      });

      if (response == null) {
        throw OrderServiceException('Order not found', code: 'ORDER_NOT_FOUND');
      }

      return Order.fromJson(response);
    } on PostgrestException catch (e) {
      throw OrderServiceException(
        'Database error while fetching order details: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      throw OrderServiceException(
        'Failed to fetch order details: $e',
        originalError: e,
      );
    }
  }

  /// Cancel pending order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      if (orderId.isEmpty) {
        throw OrderServiceException('Order ID is required', code: 'INVALID_ORDER_ID');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw OrderServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      // First check if order can be cancelled
      final order = await getOrderDetails(orderId);
      if (!order.canBeCancelled) {
        throw OrderServiceException(
          'Order cannot be cancelled in current status: ${order.status.displayName}',
          code: 'CANNOT_CANCEL',
        );
      }

      // Update order status to cancelled
      await _client
          .from(SupabaseTables.orders)
          .update({
            'status': OrderStatus.cancelled.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('user_id', userId);

      // Add status history entry
      await _client.from(SupabaseTables.orderStatusHistory).insert({
        'order_id': orderId,
        'status': OrderStatus.cancelled.name,
        'notes': reason ?? 'Cancelled by customer',
        'updated_by': userId,
      });
    } on PostgrestException catch (e) {
      throw OrderServiceException(
        'Database error while cancelling order: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      throw OrderServiceException(
        'Failed to cancel order: $e',
        originalError: e,
      );
    }
  }

  /// Track order status and get tracking information
  Future<List<Map<String, dynamic>>> trackOrder(String orderId) async {
    try {
      if (orderId.isEmpty) {
        throw OrderServiceException('Order ID is required', code: 'INVALID_ORDER_ID');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw OrderServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      // Get order status history
      final response = await _client
          .from(SupabaseTables.orderStatusHistory)
          .select('''
            status,
            notes,
            created_at,
            user_profiles!updated_by (full_name)
          ''')
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return response.map<Map<String, dynamic>>((json) => {
        'status': json['status'],
        'status_display': OrderStatus.fromString(json['status']).displayName,
        'notes': json['notes'],
        'timestamp': json['created_at'],
        'updated_by': json['user_profiles']?['full_name'] ?? 'System',
      }).toList();
    } on PostgrestException catch (e) {
      throw OrderServiceException(
        'Database error while tracking order: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is OrderServiceException) rethrow;
      throw OrderServiceException(
        'Failed to track order: $e',
        originalError: e,
      );
    }
  }

  /// Helper method to convert PaymentMethod enum to string
  String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.debitCard:
        return 'debit_card';
      case PaymentMethod.paypal:
        return 'paypal';
      case PaymentMethod.applePay:
        return 'apple_pay';
      case PaymentMethod.googlePay:
        return 'google_pay';
      case PaymentMethod.cashOnDelivery:
        return 'cash_on_delivery';
    }
  }

  /// Helper method to parse order from table response format
  Order _parseOrderFromTableResponse(Map<String, dynamic> json) {
    // Transform table response to match Order.fromJson expected format
    final transformedJson = {
      ...json,
      'delivery_address': json['customer_addresses'],
      'delivery_zone': json['delivery_zones']?['name'] ?? '',
      'delivery_slot': json['delivery_time_slots'],
      'items': (json['order_items'] as List?)?.map((item) => {
        ...item,
        'product_name': item['products']?['name'] ?? '',
        'product_image': (item['products']?['images'] as List?)?.isNotEmpty == true 
            ? item['products']['images'][0] 
            : null,
        'brand': item['products']?['brand'] ?? '',
      }).toList() ?? [],
    };

    return Order.fromJson(transformedJson);
  }
}
