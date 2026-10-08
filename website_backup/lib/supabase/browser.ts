import { createBrowserClient } from "@supabase/ssr";

export function createSupabaseBrowserClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://rcrvqrmvzvjjsmvdezts.supabase.co';
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'sb_publishable_3wgxkfeAZztYhEEFeeE6pA_NI5qf8ZE';

  return createBrowserClient(
    supabaseUrl,
    supabaseAnonKey
  );
}
