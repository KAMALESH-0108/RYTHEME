const express = require('express');
const path = require('path');
const fs = require('fs');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const musicRoutes = require('./routes/music.routes');
const userRoutes = require('./routes/user.routes');
const jamsRoutes = require('./routes/jams.routes');
const healthRoutes = require('./routes/health.routes');

const app = express();

// Middlewares
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));
app.use(cors({ origin: '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Static files for Flutter Web
const webDistPath = path.resolve(__dirname, '../../build/web');
app.use(express.static(webDistPath));

// API Routes
app.use('/api/health', healthRoutes);
app.use('/api/music', musicRoutes);
app.use('/api/user', userRoutes);
app.use('/api/jams', jamsRoutes);

// SPA fallback to Flutter Web index.html
app.get('*', (req, res) => {
  const indexPath = path.join(webDistPath, 'index.html');
  if (fs.existsSync(indexPath)) {
    return res.sendFile(indexPath);
  }
  res.json({
    name: 'RYTHEME Music Full-Stack Server',
    version: '1.0.0',
    status: 'Compiling Flutter Web... Please refresh in a few seconds'
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Error Handler]', err.stack || err);
  res.status(500).json({
    success: false,
    message: err.message || 'Internal Server Error'
  });
});

module.exports = app;
