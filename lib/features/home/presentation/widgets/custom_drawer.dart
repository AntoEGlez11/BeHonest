import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../social/presentation/leaderboard_screen.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: const Color(0xFF111827), // Gray 900
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937), // Gray 800
            ),
            child: userAsync.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent,
                    ),
                    child: Center(
                      child: Text(
                        // Random emoji based on trust level?
                        user.trustLevel > 5 ? '👑' : '🐼', 
                        style: const TextStyle(fontSize: 30)
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.alias,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${user.karma} Karma Points',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Text('Error loading profile', style: TextStyle(color: Colors.red)),
            ),
          ),
          
          if (userAsync.hasValue) ...[
             const Padding(
               padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
               child: Text('BADGES', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
             ),
             Container(
               height: 80,
               padding: const EdgeInsets.symmetric(horizontal: 16),
               child: ListView(
                 scrollDirection: Axis.horizontal,
                 children: [
                   _BadgeItem(emoji: '🌱', label: 'Newbie', unlocked: true), // Always unlocked
                   _BadgeItem(emoji: '🌮', label: 'Taco Fan', unlocked: userAsync.value!.karma >= 10),
                   _BadgeItem(emoji: '🕵️', label: 'Scout', unlocked: userAsync.value!.karma >= 50),
                   _BadgeItem(emoji: '🌟', label: 'Expert', unlocked: userAsync.value!.karma >= 100),
                 ],
               ),
             ),
             const Divider(color: Colors.white24),
          ],
          
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white70),
            title: const Text('My Ratings', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.amber),
            title: const Text('Top Scouts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('#42 Global', style: TextStyle(color: Colors.grey, fontSize: 10)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
            onTap: () {
               Navigator.pop(context); // Close drawer
               Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool unlocked;

  const _BadgeItem({required this.emoji, required this.label, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: unlocked ? Colors.blue.withValues(alpha: 0.2) : Colors.white10,
              shape: BoxShape.circle,
              border: unlocked ? Border.all(color: Colors.blueAccent) : null,
            ),
            child: Center(
              child: Text(
                unlocked ? emoji : '🔒',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
