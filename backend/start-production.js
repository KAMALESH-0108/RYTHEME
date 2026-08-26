const { spawn } = require('child_process');
const path = require('path');

console.log('====================================================');
console.log('🚀 RYTHEME Production Orchestrator Starting...');
console.log('====================================================');

// Paths
const apiDir = path.resolve(__dirname, '../jiosaavn-api');
const backendDir = path.resolve(__dirname, '.');

// 1. Start JioSaavn API Engine on Port 3000
console.log('📦 Launching JioSaavn Music Engine (Port 3000)...');
const apiProcess = spawn('node', ['node-server.js'], {
  cwd: apiDir,
  env: { ...process.env, PORT: '3000', HOST: '0.0.0.0' },
  stdio: 'inherit'
});

apiProcess.on('error', (err) => {
  console.error('❌ Failed to start JioSaavn API:', err);
});

apiProcess.on('exit', (code) => {
  if (code !== 0) {
    console.error(`⚠️ JioSaavn API exited with code ${code}`);
  }
});

// Allow API engine 1.5s to bind port before launching Express
setTimeout(() => {
  // 2. Start Express Backend & Frontend Static Server
  const port = process.env.PORT || 5000;
  console.log(`🌐 Launching Rytheme Express & Flutter Web Server (Port ${port})...`);
  
  const backendProcess = spawn('node', ['server.js'], {
    cwd: backendDir,
    env: { 
      ...process.env, 
      PORT: port.toString(), 
      JIOSAAVN_API_URL: process.env.JIOSAAVN_API_URL || 'http://localhost:3000' 
    },
    stdio: 'inherit'
  });

  backendProcess.on('error', (err) => {
    console.error('❌ Failed to start Backend Server:', err);
  });

  backendProcess.on('exit', (code) => {
    console.log(`Backend process exited with code ${code}`);
    process.exit(code || 0);
  });

  // Graceful shutdown handling
  const shutdown = () => {
    console.log('\n🛑 Shutting down Rytheme services...');
    try { apiProcess.kill('SIGTERM'); } catch (_) {}
    try { backendProcess.kill('SIGTERM'); } catch (_) {}
    process.exit(0);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}, 1500);
