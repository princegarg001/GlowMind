import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glowmind/auth/auth_manager.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthManager extends AuthManager
    with EmailSignInManager, GoogleSignInManager, AnonymousSignInManager {
  final _auth = SupabaseConfig.auth;
  final _client = SupabaseConfig.client;

  // Get the redirect URL based on platform
  String? get _redirectUrl {
    if (kIsWeb) {
      // For web, use the current origin
      return null; // Supabase handles this automatically for web
    }
    // For mobile, use deep link
    return 'io.supabase.glowmind://login-callback/';
  }

  @override
  Future<AppUser?> signInWithEmail(
      BuildContext context, String email, String password) async {
    try {
      final response =
          await _auth.signInWithPassword(email: email, password: password);
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
  Future<AppUser?> createAccountWithEmail(
      BuildContext context, String email, String password) async {
    return createAccountWithEmailAndName(context, null, email, password);
  }

  /// Create account with email, password, and optional name
  Future<AppUser?> createAccountWithEmailAndName(
    BuildContext context,
    String? name,
    String email,
    String password,
  ) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'full_name': name} : null,
      );
      if (response.user != null) {
        return await _getOrCreateUser(response.user!, name: name);
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
  Future<AppUser?> signInAnonymously(BuildContext context) async {
    try {
      final response = await _auth.signInAnonymously();
      if (response.user != null) {
        return await _getOrCreateUser(response.user!, isGuest: true);
      }
      return null;
    } on AuthException catch (e) {
      debugPrint('Anonymous sign in error: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest access failed: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Anonymous sign in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Guest access failed. Please try again.')),
        );
      }
      return null;
    }
  }

  @override
  Future<AppUser?> signInWithGoogle(BuildContext context) async {
    try {
      // For web, OAuth opens in a popup or redirect
      // For mobile, it uses external browser
      final response = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      if (response) {
        // On web, the page reloads after OAuth, so user is already set
        // Need to wait a moment for the auth state to update
        await Future.delayed(const Duration(milliseconds: 500));
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
          const SnackBar(
              content: Text('Google sign in failed. Please try again.')),
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
  Future updateEmail(
      {required String email, required BuildContext context}) async {
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
  Future resetPassword(
      {required String email, required BuildContext context}) async {
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

  Future<AppUser?> _getOrCreateUser(User supabaseUser,
      {String? name, bool isGuest = false}) async {
    try {
      final existing = await _client
          .from('users')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle();

      if (existing != null) {
        return AppUser.fromJson(existing);
      }

      // Use provided name, or fallback to metadata, or null
      final userName =
          name ?? supabaseUser.userMetadata?['full_name'] as String?;

      final newUser = {
        'id': supabaseUser.id,
        'email': supabaseUser.email,
        'name': userName,
        'is_guest': isGuest,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final inserted =
          await _client.from('users').insert(newUser).select().single();
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
