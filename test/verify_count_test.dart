import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/core/constants.dart';

void main() {
  test('Verify Business Count', () async {
    final supabase = SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseAnonKey,
    );
    
    // Simple count query
    // count(exact: true) is more expensive but accurate
    final response = await supabase
        .from('businesses')
        .count(CountOption.exact);
        
    print("✅ TOTAL BUSINESSES IN DB: $response");
  });
}
