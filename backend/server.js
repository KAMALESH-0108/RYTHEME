const app = require('./src/app');
const config = require('./src/config');

const server = app.listen(config.port, () => {
  console.log(`====================================================`);
  console.log(`🚀 RYTHEME Node.js Backend is running!`);
  console.log(`📡 URL: http://localhost:${config.port}`);
  console.log(`🎵 JioSaavn Open-Source API: ${config.jiosaavn.apiUrl}`);
  console.log(`⚡ Supabase: ${config.supabase.isConfigured() ? 'Live Connected' : 'Mock Sandbox'}`);
  console.log(`🩺 Health Check: http://localhost:${config.port}/api/health`);
  console.log(`====================================================`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
