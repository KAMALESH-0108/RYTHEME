const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const config = {
  port: parseInt(process.env.PORT, 10) || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Supabase Config
  supabase: {
    url: process.env.SUPABASE_URL || 'https://your-project-id.supabase.co',
    anonKey: process.env.SUPABASE_ANON_KEY || 'your-anon-public-key',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
    isConfigured: () => {
      const url = process.env.SUPABASE_URL || '';
      const key = process.env.SUPABASE_ANON_KEY || '';
      return url.length > 0 && !url.includes('your-project-id') && key.length > 0 && !key.includes('your-anon-public-key');
    }
  },

  // JioSaavn Open-Source API Config
  jiosaavn: {
    apiUrl: (process.env.JIOSAAVN_API_URL || 'https://saavn.dev').replace(/\/$/, ''),
    apiKey: process.env.JIOSAAVN_API_KEY || '',
    rapidApiHost: process.env.JIOSAAVN_RAPIDAPI_HOST || '',
    timeoutMs: parseInt(process.env.REQUEST_TIMEOUT_MS, 10) || 8000,
    getHeaders: () => {
      const headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'RythemeBackend/1.0.0'
      };

      if (process.env.JIOSAAVN_API_KEY) {
        if (process.env.JIOSAAVN_RAPIDAPI_HOST) {
          headers['X-RapidAPI-Key'] = process.env.JIOSAAVN_API_KEY;
          headers['X-RapidAPI-Host'] = process.env.JIOSAAVN_RAPIDAPI_HOST;
        } else {
          headers['Authorization'] = `Bearer ${process.env.JIOSAAVN_API_KEY}`;
          headers['x-api-key'] = process.env.JIOSAAVN_API_KEY;
        }
      }

      return headers;
    }
  }
};

module.exports = config;
