import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glowmind/auth/auth_manager.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/supabase/supabase_config.dart';

class SupabaseAuthManager extends AuthManager with EmailSignInManager, GoogleSignInManager {
  final _auth = SupabaseConfig.auth;
  final _client = SupabaseConfig.client;

  @override
  Future<AppUser?> signInWithEmail(BuildContext context, String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(email: email, password: password);
      if (response.user != null) {
        return await _getOrCreateUser(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Sign in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed. Please try again.')),
        );
      }
      return null;
    }
  }

  @override
  Future<AppUser?> createAccountWithEmail(BuildContext context, String email, String password) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      if (response.user != null) {
        return await _getOrCreateUser(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      debugPrint('Sign up error: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Sign up error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up failed. Please try again.')),
        );
      }
      return null;
    }
  }

  @override
  Future<AppUser?> signInWithGoogle(BuildContext context) async {
    try {
      final response = await _auth.signInWithOAuth(OAuthProvider.google);
      if (response) {
        final user = _auth.currentUser;
        if (user != null) {
          return await _getOrCreateUser(user);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign in failed. Please try again.')),
        );
      }
      return null;
    }
  }

  @override
  Future signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _client.from('users').delete().eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Delete user error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete account.')),
        );
      }
    }
  }

  @override
  Future updateEmail({required String email, required BuildContext context}) async {
    try {
      await _auth.updateUser(UserAttributes(email: email));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Update email error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update email.')),
        );
      }
    }
  }

  @override
  Future resetPassword({required String email, required BuildContext context}) async {
    try {
      await _auth.resetPasswordForEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } catch (e) {
      debugPrint('Reset password error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send password reset email.')),
        );
      }
    }
  }

  Future<AppUser?> _getOrCreateUser(User supabaseUser) async {
    try {
      final existing = await _client.from('users').select().eq('id', supabaseUser.id).maybeSingle();
      
      if (existing != null) {
        return AppUser.fromJson(existing);
      }
      
      final newUser = {
        'id': supabaseUser.id,
        'email': supabaseUser.email,
        'name': supabaseUser.userMetadata?['full_name'] as String?,
        'is_guest': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final inserted = await _client.from('users').insert(newUser).select().single();
      return AppUser.fromJson(inserted);
    } catch (e) {
      debugPrint('Error creating/fetching user: $e');
      return null;
    }
  }

  AppUser? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['full_name'] as String?,
      isGuest: false,
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }
}
