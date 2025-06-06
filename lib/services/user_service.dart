import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user by auth provider ID
  Future<AppUser?> getUserByAuthId(String authProviderId) async {
    try {
      final response = await _supabase
          .from('users_table')
          .select()
          .eq('auth_provider_id', authProviderId)
          .maybeSingle();

      return response == null ? null : AppUser.fromSupabase(response);
    } catch (e) {
      print('Error fetching user by auth ID: $e');
      return null;
    }
  }

  Future<AppUser?> getUserByUserName(String userName) async {
    try {
      final response = await _supabase
          .from('users_table')
          .select()
          .eq('user_name', userName)
          .maybeSingle(); // Use maybeSingle instead of single

      return response == null ? null : AppUser.fromSupabase(response);
    } on PostgrestException catch (e) {
      print('Database error fetching user by user_name: ${e.message}');
      return null;
    } catch (e) {
      print('Error fetching user by user_name: $e');
      return null;
    }
  }

  // Create a new user
  Future<AppUser?> createUser({
    required String userName,
    required String email,
    String? userImage,
    required UserType userType,
    required String authProviderId,
  }) async {
    try {
      final userData = {
        'user_name': userName,
        'user_image': userImage,
        'user_type': userType.value,
        'auth_provider_id': authProviderId,
      };

      final response = await _supabase
          .from('users_table')
          .insert(userData)
          .select()
          .single();

      return AppUser.fromSupabase(response);
    } on PostgrestException catch (e) {
      print('Database error creating user: ${e.message}');
      return null;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  // Get user by user ID
  Future<AppUser?> getUserById(int userId) async {
    try {
      final response = await _supabase
          .from('users_table')
          .select()
          .eq('user_id', userId)
          .single();

      return AppUser.fromSupabase(response);
    } on PostgrestException catch (e) {
      print('Database error fetching user: ${e.message}');
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  // Update user profile
  Future<AppUser?> updateUser({
    required int userId,
    String? userName,
    String? userImage,
    UserType? userType,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (userName != null) updateData['user_name'] = userName;
      if (userImage != null) updateData['user_image'] = userImage;
      if (userType != null) updateData['user_type'] = userType.value;

      if (updateData.isEmpty) return null;

      final response = await _supabase
          .from('users_table')
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();

      return AppUser.fromSupabase(response);
    } on PostgrestException catch (e) {
      print('Database error updating user: ${e.message}');
      return null;
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
  }

  // Get all users (admin only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users_table')
          .select()
          .order('user_name', ascending: true);

      return response.map((json) => AppUser.fromSupabase(json)).toList();
    } on PostgrestException catch (e) {
      print('Database error fetching users: ${e.message}');
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Delete user (admin only)
  Future<bool> deleteUser(int userId) async {
    try {
      await _supabase.from('users_table').delete().eq('user_id', userId);

      return true;
    } on PostgrestException catch (e) {
      print('Database error deleting user: ${e.message}');
      return false;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Test database connection
  Future<bool> testConnection() async {
    try {
      await _supabase
          .from('users_table')
          .select('count')
          .count(CountOption.exact);
      return true;
    } catch (e) {
      print('UserService connection test failed: $e');
      return false;
    }
  }
}
