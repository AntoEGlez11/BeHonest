import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../business/domain/business.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/data/business_repository.dart';
import '../../../auth/data/auth_repository.dart'; // Import Auth
import '../../../social/application/ai_brain.dart';


class RatingModal extends ConsumerStatefulWidget {
  final Business business;

  const RatingModal({super.key, required this.business});

  @override
  ConsumerState<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends ConsumerState<RatingModal> {
  bool _hasRated = false;
  bool _isSubmitting = false;
  bool _isOnCooldown = false;
  bool _isLoadingCheck = true;

  // Multi-Axis Scores (1-10)
  double _quality = 5;
  double _service = 5;
  double _price = 5;
  double _cleanliness = 5;
  double _waitTime = 5;

  final TextEditingController _reviewController = TextEditingController();
  final AiBrain _sentimentAnalyzer = AiBrain();
  
  bool _isThinking = false;
  double _currentSentiment = 0.0;
  Timer? _debounce;
  
  @override
  void initState() {
    super.initState();
    _checkCooldown();
    _reviewController.addListener(_onReviewChanged);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onReviewChanged() {
    // Immediate analysis for debugging
    final score = _sentimentAnalyzer.analyze(_reviewController.text);
    debugPrint('DEBUG: Instant Score: $score');
    
    setState(() {
       _currentSentiment = score;
       _isThinking = false; // continuous update
    });
  }
    



  Future<void> _checkCooldown() async {
    final canRate = await ref.read(authRepositoryProvider).canRateBusiness(widget.business.id);
    if (mounted) {
      setState(() {
        _isOnCooldown = !canRate;
        _isLoadingCheck = false;
      });
    }
  }

  Future<void> _submitRating() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      final user = await ref.read(currentUserProvider.future); // Get current user
        
      final scores = {
        'quality': _quality.round(),
        'service': _service.round(),
        'price': _price.round(),
        'cleanliness': _cleanliness.round(),
        'wait_time': _waitTime.round(),
      };

      await ref.read(businessRepositoryProvider).rateBusinessMultiAxis(
        widget.business.id,
        scores,
        userId: user.id,
        comment: _reviewController.text, // Pass the honest opinion
      );
      
      // Award Karma & Record Rating
      await ref.read(authRepositoryProvider).awardKarma(10);
      await ref.read(authRepositoryProvider).recordRating(widget.business.id);
      
      // Refresh the user provider
      ref.read(authParamsProvider.notifier).state++; 

      if (mounted) {
        setState(() {
          _hasRated = true;
          _isSubmitting = false;
        });
      }
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) Navigator.pop(context);
      });

    } catch (e) {
      debugPrint('Error rating: $e');
      setState(() => _isSubmitting = false);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error submitting rating')));
      }
    }
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            Text(value.round().toString(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.grey[700],
            thumbColor: Colors.white,
            overlayColor: Colors.blueAccent.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85, // Taller modal
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
          
          if (_isLoadingCheck) ...[
             const Spacer(),
             const CircularProgressIndicator(color: Colors.blueAccent),
             const Spacer(),
          ] else if (_isOnCooldown) ...[
             const Spacer(),
             const Icon(Icons.timer, color: Colors.amber, size: 80)
                 .animate()
                 .shake(duration: 500.ms),
             const SizedBox(height: 24),
             const Text(
               'Cooldown Active',
               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
             ),
             const SizedBox(height: 8),
             const Text(
               'Please wait 24 hours between reviews\nfor the same business.',
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.grey),
             ),
             const Spacer(),
          ] else if (_hasRated) ...[
            const Spacer(),
            const Icon(Icons.check_circle, color: Colors.green, size: 80)
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'Rating Submitted!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              'Your opinion shapes the map.',
              style: TextStyle(color: Colors.grey),
            ),
             const Spacer(),
          ] else ...[
            Text(
              widget.business.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Rate your experience (1-10)',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSlider('Quality / Taste', _quality, (v) => setState(() => _quality = v)),
                    const SizedBox(height: 16),
                    _buildSlider('Service / Staff', _service, (v) => setState(() => _service = v)),
                    const SizedBox(height: 16),
                    _buildSlider('Cleanliness', _cleanliness, (v) => setState(() => _cleanliness = v)),
                    const SizedBox(height: 16),
                    _buildSlider('Value for Money', _price, (v) => setState(() => _price = v)),
                    const SizedBox(height: 16),
                     _buildSlider('Speed / Wait Time', _waitTime, (v) => setState(() => _waitTime = v)),
                     
                     const SizedBox(height: 32),
                     
                     // DEBUG READOUT REMOVED
                     const SizedBox(height: 8),
                     _buildTruthGuard(),
                     const SizedBox(height: 8),

                     // Review Text Field
                     TextField(
                       controller: _reviewController,
                       maxLines: 3,
                       style: const TextStyle(color: Colors.white),
                       decoration: InputDecoration(
                         hintText: 'Share your honest opinion...',
                         hintStyle: TextStyle(color: Colors.grey[600]),
                         filled: true,
                         fillColor: Colors.black26,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                       ),
                       onChanged: (text) => _onReviewChanged(),
                     ),
                     
                     const SizedBox(height: 16),
                     _buildTruthGuard(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildTruthGuard() {
    // 1. Thinking State
    if (_isThinking) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1000.ms, color: Colors.white),
          const SizedBox(width: 8),
          const Text('AI is analyzing...', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
        ],
      );
    }

    // 2. Conflict Detection
    final avgScore = (_quality + _service + _price + _cleanliness + _waitTime) / 5;
    bool conflictDetected = false;
    String warningMsg = '';

    // High Score (>8) but Negative Text
    if (avgScore >= 8 && _currentSentiment < -0.1) {
      conflictDetected = true;
      warningMsg = '🤔 You rated highly, but your text sounds negative. Is this honest?';
    }
    // Low Score (<3) but Positive Text
    else if (avgScore <= 3 && _currentSentiment > 0.3) {
      conflictDetected = true;
      warningMsg = '🤔 You rated poorly, but your text sounds positive. Did you miss-click?';
    }
    
    print('RatingModal: Avg=$avgScore, Sentiment=$_currentSentiment, Conflict=$conflictDetected');

    if (conflictDetected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                warningMsg,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.2, end: 0);
    }

    return const SizedBox.shrink();
  }
}
