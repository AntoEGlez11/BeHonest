import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user_profile.dart';

class TrustService {
  /// Calculates the weight of a user's review based on their Karma/Trust.
  /// Base weight is 1.0. 
  /// High trust users can have up to 2.0x impact.
  double calculateEffectiveWeight(UserProfile user) {
    if (user.karma < 10) return 0.5; // Newbie penalty
    if (user.karma < 50) return 1.0; // Standard
    if (user.karma < 100) return 1.2; // Reliable
    if (user.karma < 500) return 1.5; // Expert
    return 2.0; // Authority (Taco God)
  }

  /// Updates trust level based on Karma.
  /// Returns the new Trust Level integer.
  int calculateTrustLevel(int karma) {
    if (karma < 10) return 1; // Newbie
    if (karma < 50) return 2; // Member
    if (karma < 100) return 3; // Verified
    if (karma < 500) return 4; // Expert
    return 5; // Legend
  }
}

final trustServiceProvider = Provider<TrustService>((ref) {
  return TrustService();
});
