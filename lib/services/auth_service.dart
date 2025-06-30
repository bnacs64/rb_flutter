import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/user_model.dart';

/// Custom exception for auth service errors
class AuthServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AuthServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AuthServiceException: $message';
}

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
      if (email.isEmpty) {
        throw AuthServiceException('Email is required', code: 'INVALID_EMAIL');
      }
      if (password.isEmpty) {
        throw AuthServiceException('Password is required',
            code: 'INVALID_PASSWORD');
      }
      if (password.length < 6) {
        throw AuthServiceException('Password must be at least 6 characters',
            code: 'PASSWORD_TOO_SHORT');
      }

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
    } on AuthException catch (e) {
      throw AuthServiceException(
        'Authentication error: ${e.message}',
        code: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      throw AuthServiceException(
        'Failed to sign up: $e',
        originalError: e,
      );
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
      if (dateOfBirth != null) {
        updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      }
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

  /// Change password with current password verification
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentPassword.isEmpty) {
        throw AuthServiceException('Current password is required',
            code: 'INVALID_CURRENT_PASSWORD');
      }
      if (newPassword.isEmpty) {
        throw AuthServiceException('New password is required',
            code: 'INVALID_NEW_PASSWORD');
      }
      if (newPassword.length < 6) {
        throw AuthServiceException('New password must be at least 6 characters',
            code: 'PASSWORD_TOO_SHORT');
      }

      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw AuthServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // Verify current password by attempting to sign in
      try {
        await _client.auth.signInWithPassword(
          email: currentUser.email!,
          password: currentPassword,
        );
      } catch (e) {
        throw AuthServiceException('Current password is incorrect',
            code: 'INVALID_CURRENT_PASSWORD');
      }

      // Update to new password
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthServiceException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthServiceException(
        'Authentication error: ${e.message}',
        code: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw AuthServiceException(
        'Failed to change password: $e',
        originalError: e,
      );
    }
  }

  /// Update password (for password reset flow)
  Future<void> updatePassword(String newPassword) async {
    try {
      if (newPassword.isEmpty) {
        throw AuthServiceException('New password is required',
            code: 'INVALID_PASSWORD');
      }
      if (newPassword.length < 6) {
        throw AuthServiceException('Password must be at least 6 characters',
            code: 'PASSWORD_TOO_SHORT');
      }

      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw AuthServiceException(
        'Authentication error: ${e.message}',
        code: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      throw AuthServiceException(
        'Failed to update password: $e',
        originalError: e,
      );
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

  /// Delete user account
  Future<void> deleteAccount({String? password}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw AuthServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // If password is provided, verify it first
      if (password != null &&
          password.isNotEmpty &&
          currentUser.email != null) {
        try {
          await _client.auth.signInWithPassword(
            email: currentUser.email!,
            password: password,
          );
        } catch (e) {
          throw AuthServiceException('Password verification failed',
              code: 'INVALID_PASSWORD');
        }
      }

      final userId = currentUser.id;

      // Delete user profile and related data (handled by CASCADE in database)
      await _client.from(SupabaseTables.userProfiles).delete().eq('id', userId);

      // Sign out the user
      await _client.auth.signOut();
    } on AuthServiceException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthServiceException(
        'Authentication error: ${e.message}',
        code: e.statusCode,
        originalError: e,
      );
    } on PostgrestException catch (e) {
      throw AuthServiceException(
        'Database error while deleting account: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AuthServiceException(
        'Failed to delete account: $e',
        originalError: e,
      );
    }
  }

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
