import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/address_model.dart';
import '../models/order_model.dart'; // For DeliveryTimeSlot

/// Custom exception for address service errors
class AddressServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AddressServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AddressServiceException: $message';
}

/// Service for managing customer addresses and delivery options
class AddressService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get user's saved addresses
  Future<List<CustomerAddress>> getUserAddresses() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw AddressServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      final response = await _client
          .from(SupabaseTables.customerAddresses)
          .select('*')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return response.map<CustomerAddress>((json) => CustomerAddress.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AddressServiceException(
        'Database error while fetching addresses: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AddressServiceException) rethrow;
      throw AddressServiceException(
        'Failed to fetch user addresses: $e',
        originalError: e,
      );
    }
  }

  /// Add new delivery address
  Future<CustomerAddress> addAddress({
    required String label,
    required String fullName,
    String? phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String postalCode,
    String? province,
    String country = 'Canada',
    double? latitude,
    double? longitude,
    String? deliveryInstructions,
    bool isDefault = false,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw AddressServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      // Validate required fields
      if (label.isEmpty) {
        throw AddressServiceException('Address label is required', code: 'INVALID_LABEL');
      }
      if (fullName.isEmpty) {
        throw AddressServiceException('Full name is required', code: 'INVALID_NAME');
      }
      if (addressLine1.isEmpty) {
        throw AddressServiceException('Address line 1 is required', code: 'INVALID_ADDRESS');
      }
      if (city.isEmpty) {
        throw AddressServiceException('City is required', code: 'INVALID_CITY');
      }
      if (postalCode.isEmpty) {
        throw AddressServiceException('Postal code is required', code: 'INVALID_POSTAL_CODE');
      }

      // If this is set as default, unset other default addresses first
      if (isDefault) {
        await _client
            .from(SupabaseTables.customerAddresses)
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      final response = await _client
          .from(SupabaseTables.customerAddresses)
          .insert({
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
          })
          .select()
          .single();

      return CustomerAddress.fromJson(response);
    } on PostgrestException catch (e) {
      throw AddressServiceException(
        'Database error while adding address: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AddressServiceException) rethrow;
      throw AddressServiceException(
        'Failed to add address: $e',
        originalError: e,
      );
    }
  }

  /// Update existing address
  Future<CustomerAddress> updateAddress({
    required String addressId,
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
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw AddressServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      if (addressId.isEmpty) {
        throw AddressServiceException('Address ID is required', code: 'INVALID_ADDRESS_ID');
      }

      // Build update data with only non-null values
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (label != null) updateData['label'] = label;
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (addressLine1 != null) updateData['address_line_1'] = addressLine1;
      if (addressLine2 != null) updateData['address_line_2'] = addressLine2;
      if (city != null) updateData['city'] = city;
      if (postalCode != null) updateData['postal_code'] = postalCode;
      if (province != null) updateData['province'] = province;
      if (country != null) updateData['country'] = country;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (deliveryInstructions != null) updateData['delivery_instructions'] = deliveryInstructions;
      if (isDefault != null) updateData['is_default'] = isDefault;

      // If this is set as default, unset other default addresses first
      if (isDefault == true) {
        await _client
            .from(SupabaseTables.customerAddresses)
            .update({'is_default': false})
            .eq('user_id', userId)
            .neq('id', addressId);
      }

      final response = await _client
          .from(SupabaseTables.customerAddresses)
          .update(updateData)
          .eq('id', addressId)
          .eq('user_id', userId)
          .select()
          .single();

      return CustomerAddress.fromJson(response);
    } on PostgrestException catch (e) {
      throw AddressServiceException(
        'Database error while updating address: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AddressServiceException) rethrow;
      throw AddressServiceException(
        'Failed to update address: $e',
        originalError: e,
      );
    }
  }

  /// Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw AddressServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      if (addressId.isEmpty) {
        throw AddressServiceException('Address ID is required', code: 'INVALID_ADDRESS_ID');
      }

      await _client
          .from(SupabaseTables.customerAddresses)
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AddressServiceException(
        'Database error while deleting address: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AddressServiceException) rethrow;
      throw AddressServiceException(
        'Failed to delete address: $e',
        originalError: e,
      );
    }
  }

  /// Get available delivery zones for a specific location
  Future<List<DeliveryZone>> getDeliveryZones({
    double? latitude,
    double? longitude,
  }) async {
    try {
      List<DeliveryZone> zones;

      if (latitude != null && longitude != null) {
        // Use RPC function to get zones for specific coordinates
        final response = await _client.rpc('get_delivery_zones_for_address', params: {
          'latitude_param': latitude,
          'longitude_param': longitude,
        });

        zones = (response as List?)?.map<DeliveryZone>((json) => DeliveryZone.fromJson(json)).toList() ?? [];
      } else {
        // Get all active delivery zones
        final response = await _client
            .from(SupabaseTables.deliveryZones)
            .select('*')
            .eq('is_active', true)
            .order('name');

        zones = response.map<DeliveryZone>((json) => DeliveryZone.fromJson(json)).toList();
      }

      return zones;
    } on PostgrestException catch (e) {
      throw AddressServiceException(
        'Database error while fetching delivery zones: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AddressServiceException) rethrow;
      throw AddressServiceException(
        'Failed to fetch delivery zones: $e',
        originalError: e,
      );
    }
  }

  /// Get available delivery time slots for a zone and date
  Future<List<DeliveryTimeSlot>> getAvailableSlots({
    required String zoneId,
    required DateTime date,
  }) async {
    try {
      if (zoneId.isEmpty) {
        throw AddressServiceException('Zone ID is required', code: 'INVALID_ZONE_ID');
      }

      final dateString = date.toIso8601String().split('T')[0]; // Get date part only

      final response = await _client.rpc('get_available_delivery_slots', params: {
        'zone_id_param': zoneId,
        'delivery_date_param': dateString,
      });

      return (response as List?)?.map<DeliveryTimeSlot>((json) => DeliveryTimeSlot.fromJson(json)).toList() ?? [];
    } on PostgrestException catch (e) {
      throw AddressServiceException(
        'Database error while fetching delivery slots: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AddressServiceException) rethrow;
      throw AddressServiceException(
        'Failed to fetch delivery slots: $e',
        originalError: e,
      );
    }
  }

  /// Set address as default
  Future<void> setDefaultAddress(String addressId) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw AddressServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      if (addressId.isEmpty) {
        throw AddressServiceException('Address ID is required', code: 'INVALID_ADDRESS_ID');
      }

      // First, unset all default addresses for the user
      await _client
          .from(SupabaseTables.customerAddresses)
          .update({'is_default': false})
          .eq('user_id', userId);

      // Then set the specified address as default
      await _client
          .from(SupabaseTables.customerAddresses)
          .update({'is_default': true})
          .eq('id', addressId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AddressServiceException(
        'Database error while setting default address: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AddressServiceException) rethrow;
      throw AddressServiceException(
        'Failed to set default address: $e',
        originalError: e,
      );
    }
  }

  /// Get default address for the user
  Future<CustomerAddress?> getDefaultAddress() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw AddressServiceException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      final response = await _client
          .from(SupabaseTables.customerAddresses)
          .select('*')
          .eq('user_id', userId)
          .eq('is_default', true)
          .limit(1);

      if (response.isEmpty) return null;

      return CustomerAddress.fromJson(response.first);
    } on PostgrestException catch (e) {
      throw AddressServiceException(
        'Database error while fetching default address: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AddressServiceException) rethrow;
      throw AddressServiceException(
        'Failed to fetch default address: $e',
        originalError: e,
      );
    }
  }
}
