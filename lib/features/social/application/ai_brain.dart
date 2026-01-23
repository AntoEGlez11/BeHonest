class AiBrain {
  // Simple heuristics for MVP (Client-side, Instant, No API cost)

  /// Returns a score from -1.0 (Negative) to 1.0 (Positive)
  /// 0.0 is Neutral or Unknown
  double analyze(String text) {
    if (text.isEmpty) return 0.0;
    
    const Set<String> positiveWords = {
      'good', 'great', 'amazing', 'love', 'best', 'delicious', 'tasty', 
      'excellent', 'nice', 'friendly', 'clean', 'fast', 'awesome', 'perfect',
      'bueno', 'rico', 'excelente', 'amable', 'limpio', 'rapido', 'encanta',
      'bien', 'maravilla'
    };

    const Set<String> negativeWords = {
      'bad', 'terrible', 'worst', 'hate', 'awful', 'rude', 'dirty', 'slow',
      'gross', 'horrible', 'disgusting', 'expensive', 'noisy',
      'malo', 'pesimo', 'odio', 'sucio', 'lento', 'caro', 'ruidoso',
      'feo', 'desastre'
    };

    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\s+')); // Split by whitespace
    
    int score = 0;
    int relevantWords = 0;

    for (final word in words) {
      // Remove punctuation
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
      
      if (positiveWords.contains(cleanWord)) {
        score++;
        relevantWords++;
      } else if (negativeWords.contains(cleanWord)) {
        score--;
        relevantWords++;
      }
    }

    if (relevantWords == 0) return 0.0;

    // Normalize to -1.0 to 1.0
    double normalized = score / (relevantWords + 2);
    if (normalized > 1.0) normalized = 1.0;
    if (normalized < -1.0) normalized = -1.0;
    
    print('AiBrain: Text="$text" -> Score=$score, Relevant=$relevantWords, Normalized=$normalized');
    return normalized;
  }
}
