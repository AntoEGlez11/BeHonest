import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActivityFeedOverlay extends StatefulWidget {
  const ActivityFeedOverlay({super.key});

  @override
  State<ActivityFeedOverlay> createState() => _ActivityFeedOverlayState();
}

class _ActivityFeedOverlayState extends State<ActivityFeedOverlay> {
  final List<String> _activities = [];
  final List<String> _mockEvents = [
    "🐼 Anon Panda rated Tacos El Dev 5/5",
    "🌮 Burger King received a new review",
    "🚲 Bike Shop was added by User #921",
    "🌟 Juan just reached Trust Level 2!",
    "🕵️ New Scout detected in Monterrey",
    "🍜 Ramen Place: 'Best soup ever'",
  ];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Add initial event
    _activities.add(_mockEvents[0]);
    
    // Simulate live feed
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        final newEvent = _mockEvents[DateTime.now().second % _mockEvents.length];
        _activities.insert(0, newEvent);
        if (_activities.length > 3) _activities.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60, // Below search bar
      left: 0,
      right: 0,
      child: IgnorePointer( // Don't block map touches
        child: Column(
          children: _activities.map((text) {
            // Unique key based on content + timestamp roughly to force rebuild/animate
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public, color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    text, 
                    style: const TextStyle(color: Colors.white, fontSize: 12)
                  ),
                ],
              ),
            ).animate()
             .fadeIn(duration: 400.ms)
             .slideY(begin: -0.5, end: 0)
             .then(delay: 2500.ms) // Usage: Stay for 2.5s
             .fadeOut(duration: 400.ms);
          }).toList(),
        ),
      ),
    );
  }
}
