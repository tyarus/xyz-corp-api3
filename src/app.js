/**
 * XYZ Corp REST API
 * Server aplikasi utama dengan Express.js
 * 
 * Fitur:
 * - CORS enabled untuk cross-origin requests
 * - Morgan logger untuk tracking HTTP requests
 * - Custom middleware untuk logging detail
 * - Seed data untuk proyek dan karyawan
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

// Import routes
const projectsRouter = require('./routes/projects');
const employeesRouter = require('./routes/employees');

// Import middleware
const customLogger = require('./middleware/logger');

// Inisialisasi Express app
const app = express();

// Konfigurasi environment variables
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const API_VERSION = process.env.API_VERSION || '1.0.0';
const API_NAME = process.env.API_NAME || 'XYZ Corp REST API';

// ============================================
// MIDDLEWARE
// ============================================

// CORS middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parser middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Morgan HTTP logger
app.use(morgan('combined'));

// Custom logger middleware
app.use(customLogger);

// ============================================
// ROUTES
// ============================================

/**
 * GET / 
 * Health check endpoint + info tentang API
 */
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'XYZ Corp REST API is running',
    api_name: API_NAME,
    version: API_VERSION,
    environment: NODE_ENV,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    endpoints: {
      health_check: 'GET /',
      projects: {
        list_all: 'GET /api/projects',
        create: 'POST /api/projects',
        detail: 'GET /api/projects/:id',
        update: 'PUT /api/projects/:id',
        delete: 'DELETE /api/projects/:id'
      },
      employees: {
        list_all: 'GET /api/employees',
        detail: 'GET /api/employees/:id'
      },
      statistics: 'GET /api/stats'
    }
  });
});

// Routes untuk projects dan employees
app.use('/api/projects', projectsRouter);
app.use('/api/employees', employeesRouter);

/**
 * GET /api/stats
 * Statistik keseluruhan tentang proyek dan tim
 */
app.get('/api/stats', (req, res) => {
  // Simulasi data dari in-memory database (dalam production dari database real)
  const projects = [
    { id: 1, status: 'active', progress: 65 },
    { id: 2, status: 'active', progress: 45 },
    { id: 3, status: 'completed', progress: 100 },
    { id: 4, status: 'pending', progress: 15 },
    { id: 5, status: 'active', progress: 80 }
  ];
  
  const stats = {
    success: true,
    message: 'Statistik proyek berhasil diambil',
    timestamp: new Date().toISOString(),
    summary: {
      total_projects: projects.length,
      active: projects.filter(p => p.status === 'active').length,
      completed: projects.filter(p => p.status === 'completed').length,
      pending: projects.filter(p => p.status === 'pending').length,
      avg_progress: Math.round(projects.reduce((sum, p) => sum + p.progress, 0) / projects.length)
    },
    breakdown: {
      by_status: {
        active: projects.filter(p => p.status === 'active').length,
        completed: projects.filter(p => p.status === 'completed').length,
        pending: projects.filter(p => p.status === 'pending').length
      },
      by_progress: {
        '0-25%': projects.filter(p => p.progress <= 25).length,
        '25-50%': projects.filter(p => p.progress > 25 && p.progress <= 50).length,
        '50-75%': projects.filter(p => p.progress > 50 && p.progress <= 75).length,
        '75-100%': projects.filter(p => p.progress > 75).length
      }
    }
  };
  
  res.json(stats);
});

// ============================================
// ERROR HANDLING
// ============================================

/**
 * 404 - Not Found Handler
 */
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`,
    available_endpoints: [
      'GET /',
      'GET /api/projects',
      'POST /api/projects',
      'GET /api/projects/:id',
      'PUT /api/projects/:id',
      'DELETE /api/projects/:id',
      'GET /api/employees',
      'GET /api/employees/:id',
      'GET /api/stats'
    ]
  });
});

/**
 * Error handling middleware
 */
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Terjadi kesalahan server internal',
    error: NODE_ENV === 'development' ? err.message : 'Internal Server Error'
  });
});

// ============================================
// START SERVER
// ============================================

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║         XYZ CORP REST API - SERVER STARTED             ║
╠════════════════════════════════════════════════════════╣
║ API Name     : ${API_NAME.padEnd(36)}║
║ Version      : ${API_VERSION.padEnd(36)}║
║ Environment  : ${NODE_ENV.padEnd(36)}║
║ Port         : ${PORT.toString().padEnd(36)}║
║ Timestamp    : ${new Date().toISOString().padEnd(36)}║
╠════════════════════════════════════════════════════════╣
║ Server URL   : http://localhost:${PORT}${' '.repeat(28 - PORT.toString().length)}║
║ Health Check : http://localhost:${PORT}/ ${' '.repeat(22 - PORT.toString().length)}║
║ API Base     : http://localhost:${PORT}/api${' '.repeat(18 - PORT.toString().length)}║
╚════════════════════════════════════════════════════════╝
  `);
});

module.exports = app;
