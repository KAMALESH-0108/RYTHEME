class RythemeConfig {
  // ==========================================
  // 1. SUPABASE BACKEND CONFIGURATION
  // ==========================================
  // Replace these with your actual Supabase URL and Anon Key from the Supabase Dashboard
  // Dashboard: https://app.supabase.com -> Project Settings -> API
  static const String supabaseUrl = 'https://dpnxxrmvahyfzpfwhrey.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwbnh4cm12YWh5ZnpwZndocmV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc3MDU2MDgsImV4cCI6MjEwMzI4MTYwOH0.IfsjEJNJ1GQTFluzdhf3ccc3xb-1voAJTJpYX4krmVY';

  // Helper to check if actual credentials have been filled in
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project-id') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('your-anon-public-key');

  // ==========================================
  // 2. JIOSAAVN OPEN-SOURCE API CONFIGURATION
  // ==========================================
  // Open-Source JioSaavn API instances:
  // - Self-Hosted Local Instance: http://localhost:3000
  // - Public Instance: https://saavn.dev
  // - Official repo: https://github.com/sumitkolhe/jiosaavn-api
  static const String jioSaavnApiUrl = 'http://localhost:3000';
  
  // Optional API Key for protected/private instances or RapidAPI
  static const String jioSaavnApiKey = ''; 

  // Optional RapidAPI Host (if using RapidAPI JioSaavn instance)
  static const String jioSaavnRapidApiHost = '';

  // Generates request headers dynamically based on configured keys
  static Map<String, String> getSaavnHeaders() {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (jioSaavnApiKey.isNotEmpty) {
      // Support RapidAPI or custom header authentication
      if (jioSaavnRapidApiHost.isNotEmpty) {
        headers['X-RapidAPI-Key'] = jioSaavnApiKey;
        headers['X-RapidAPI-Host'] = jioSaavnRapidApiHost;
      } else {
        // Standard Bearer or x-api-key header for custom self-hosted proxy
        headers['Authorization'] = 'Bearer $jioSaavnApiKey';
        headers['x-api-key'] = jioSaavnApiKey;
      }
    }

    return headers;
  }

  // ==========================================
  // 3. NODE.JS BACKEND SERVER CONFIGURATION
  // ==========================================
  // If you run the Node.js backend locally or deployed on cloud:
  // - Local Android Emulator: http://10.0.2.2:5000
  // - Local Desktop/Web/iOS: http://localhost:5000
  // - Production: https://your-backend.onrender.com
  static const String nodeBackendUrl = 'http://localhost:5000';
  static const bool useNodeBackend = true; // Toggle to true to route all requests via Node.js server

  // ==========================================
  // 4. APP BRANDING & SYSTEM CONFIGURATION
  // ==========================================
  static const String appName = 'RYTHEME';
  static const String appTagline = 'Find Your Sound. Feel Your Moment.';
  static const String appVersion = '1.0.0';
  
  // Audio playback defaults
  static const int defaultAudioBitrate = 320; // 320kbps (highest quality)
  static const int requestTimeoutSeconds = 8;
}
