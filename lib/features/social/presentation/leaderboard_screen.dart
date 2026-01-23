import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final List<Map<String, dynamic>> _mockUsers = [
    {'alias': 'Taco King 🌮', 'karma': 2450, 'rank': 1, 'avatar': '👑'},
    {'alias': 'Anon Panda 🐼', 'karma': 1890, 'rank': 2, 'avatar': '🐼'},
    {'alias': 'Cyber Truck 🚙', 'karma': 1420, 'rank': 3, 'avatar': '🚙'},
    {'alias': 'Salsa Queen 💃', 'karma': 980, 'rank': 4, 'avatar': '💃'},
    {'alias': 'Night Owl 🦉', 'karma': 850, 'rank': 5, 'avatar': '🦉'},
    {'alias': 'You (Newbie)', 'karma': 50, 'rank': 42, 'avatar': '👤'},
  ];

  @override
  Widget build(BuildContext context) {
    // Sort just in case
    _mockUsers.sort((a, b) => b['karma'].compareTo(a['karma']));
    
    final podium = _mockUsers.take(3).toList();
    final list = _mockUsers.skip(3).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        appBar: AppBar(
          title: const Text('Top Scouts'),
          backgroundColor: const Color(0xFF111827),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: 'Local (Monterrey)'),
              Tab(text: 'Global'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLeaderboardView(podium, list),
            const Center(child: Text('Coming Soon...', style: TextStyle(color: Colors.white54))), // Global/Friends placeholder
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardView(List<Map<String, dynamic>> podium, List<Map<String, dynamic>> list) {
    return CustomScrollView(
      slivers: [
        // Podium Area
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPodiumItem(podium[1], 2), // Silver (Left)
                _buildPodiumItem(podium[0], 1), // Gold (Center, Taller)
                _buildPodiumItem(podium[2], 3), // Bronze (Right)
              ],
            ),
          ),
        ),
        
        // The List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final user = list[index];
              final isMe = user['alias'].toString().contains('You');
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isMe ? Border.all(color: Colors.blueAccent) : null,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Text(user['avatar']),
                  ),
                  title: Text(
                    user['alias'],
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${user['karma']}', 
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                    ],
                  ),
                  leadingAndTrailingTextStyle: const TextStyle(fontSize: 16),
                ),
              ).animate().fadeIn(delay: (100 * index).ms).slideX();
            },
            childCount: list.length,
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int place) {
    final bool isFirst = place == 1;
    final double height = isFirst ? 160 : 130;
    final Color color = place == 1 ? Colors.amber : (place == 2 ? Colors.grey[300]! : Colors.brown[300]!);
    
    return Column(
      children: [
        Text(user['avatar'], style: const TextStyle(fontSize: 40))
            .animate()
            .scale(delay: (200 * place).ms, curve: Curves.elasticOut),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$place', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: color
                )
              ),
              const SizedBox(height: 8),
              Text(
                '${user['karma']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            user['alias'],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
