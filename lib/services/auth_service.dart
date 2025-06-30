import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/user_model.dart';

/// Service for authentication and user management
class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Sign up with email and password
  Future<UserProfile?> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        // Get the user profile that was created by the trigger
        return await getUserProfile();
      }

      return null;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sign in with email and password
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await getUserProfile();
      }

      return null;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Get current user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return null;

      final response = await _client.rpc('get_user_profile', params: {
        'user_id_param': userId,
      });

      if (response == null) return null;

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user profile
  Future<UserProfile?> updateUserProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (preferences != null) updateData['preferences'] = preferences;

      await _client
          .from(SupabaseTables.userProfiles)
          .update(updateData)
          .eq('id', userId);

      return await getUserProfile();
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => SupabaseConfig.isAuthenticated;

  /// Get current user
  User? get currentUser => SupabaseConfig.currentUser;

  /// Get current user ID
  String? get currentUserId => SupabaseConfig.currentUserId;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Add customer address
  Future<CustomerAddress> addCustomerAddress({
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    String? landmark,
    bool isDefault = false,
    String addressType = 'home',
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from(SupabaseTables.customerAddresses)
          .insert({
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
          })
          .select()
          .single();

      return CustomerAddress.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add customer address: $e');
    }
  }

  /// Get customer addresses
  Future<List<CustomerAddress>> getCustomerAddresses() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from(SupabaseTables.customerAddresses)
          .select('*')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return response.map((json) => CustomerAddress.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get customer addresses: $e');
    }
  }
}
