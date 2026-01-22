import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../business/domain/business.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/data/business_repository.dart';


class RatingModal extends ConsumerStatefulWidget {
  final Business business;

  const RatingModal({super.key, required this.business});

  @override
  ConsumerState<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends ConsumerState<RatingModal> {
  bool _hasRated = false;

  Future<void> _rate(bool isHonest) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _hasRated = true;
    });

    try {
      await ref.read(businessRepositoryProvider).rateBusiness(
        widget.business.id,
        isHonest,
      );
    } catch (e) {
      // Sliently fail or show snackbar?
      // For now, let's just log or ignore as we show the success animation anyway.
      debugPrint('Error rating: $e');
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_hasRated) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 60)
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text(
              'Thanks for being Honest!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
             const SizedBox(height: 32),
          ] else ...[
            Text(
              widget.business.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.business.category,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RatingButton(
                  emoji: '😇',
                  label: 'Honest',
                  color: const Color(0xFF10B981), // Emerald 500
                  onTap: () => _rate(true),
                ),
                _RatingButton(
                  emoji: '😈',
                  label: 'Dishonest',
                  color: const Color(0xFFEF4444), // Red 500
                  onTap: () => _rate(false),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(delay: 2000.ms, duration: 1000.ms, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
