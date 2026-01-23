import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  static const String kUserKey = 'behonest_user_profile';
  
  Future<UserProfile> ensureUserIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(kUserKey);

    if (jsonString != null) {
      // Return existing user
      return UserProfile.fromJson(jsonDecode(jsonString));
    } else {
      // Create new anonymous user
      final newUser = UserProfile(
        id: const Uuid().v4(),
        alias: 'Anonymous Panda ${DateTime.now().millisecond}', // Fun alias
        karma: 0,
        trustLevel: 1,
      );
      
      await saveUser(newUser);
      return newUser;
    }
  }

  Future<void> awardKarma(int points) async {
    final user = await ensureUserIdentity();
    final newKarma = user.karma + points;
    
    // Recalculate Trust Level
    // Simple logic for now: 10 karma = Level 2, 50 = Level 3
    int newTrust = 1;
    if (newKarma >= 10) newTrust = 2;
    if (newKarma >= 50) newTrust = 3;
    if (newKarma >= 100) newTrust = 4;
    
    final updatedUser = user.copyWith(karma: newKarma, trustLevel: newTrust);
    await saveUser(updatedUser);
    print('Karma awarded! Balance: $newKarma. Trust Level: $newTrust');
  }

  /// Checks if the user is allowed to rate a specific business (24h Policy)
  Future<bool> canRateBusiness(String businessId) async {
    final user = await ensureUserIdentity();
    final lastRatingStr = user.lastRatings[businessId];
    
    if (lastRatingStr == null) return true; // Never rated
    
    final lastRating = DateTime.parse(lastRatingStr);
    final difference = DateTime.now().difference(lastRating);
    
    return difference.inHours >= 24;
  }

  /// Records a successful rating to enforce the policy
  Future<void> recordRating(String businessId) async {
    final user = await ensureUserIdentity();
    final newRatings = Map<String, String>.from(user.lastRatings);
    newRatings[businessId] = DateTime.now().toIso8601String();
    
    final updatedUser = user.copyWith(lastRatings: newRatings);
    await saveUser(updatedUser);
  }

  Future<void> saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kUserKey, jsonEncode(user.toJson()));
  }
}

// Invalidate provider to force refresh after karma update
final authParamsProvider = StateProvider((ref) => 0);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  // Watch a trigger to allow manual refresh
  ref.watch(authParamsProvider);
  return ref.read(authRepositoryProvider).ensureUserIdentity();
});
