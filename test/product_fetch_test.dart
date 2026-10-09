import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://rcrvqrmvzvjjsmvdezts.supabase.co',
    'sb_publishable_3wgxkfeAZztYhEEFeeE6pA_NI5qf8ZE',
  );

  try {
    final response = await supabase
        .from('products')
        .select('''
          *,
          categories ( id, name ),
          inventory ( store_id, stock_quantity )
        ''')
        .eq('active', true)
        .order('name');
    print('Fetched ${response.length} products successfully!');
    if (response.isNotEmpty) {
      print('First item: ${response.first}');
    }
  } catch (e, st) {
    print('Error: $e');
    print(st);
  }
}
