class EnvConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rcrvqrmvzvjjsmvdezts.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_3wgxkfeAZztYhEEFeeE6pA_NI5qf8ZE',
  );

  // Razorpay Test Public Key ID & Secret
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_TdqvfphMNs2TI8',
  );

  static const String razorpayKeySecret = String.fromEnvironment(
    'RAZORPAY_KEY_SECRET',
    defaultValue: 'Sv40IOE6fPpgWFHd8CEs5VHC',
  );

  // Backend Base URL for secure server-side orders & Razorpay signature verification
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://effulgent-paprenjak-5573e1.netlify.app',
  );

  // App Metadata
  static const String appName = 'K MART';
  static const String appTagline = 'Daily Essentials, Delivered';
  static const String defaultStoreId = '458cbfde-68fd-4e71-86c7-a12a4cecad4d';
}