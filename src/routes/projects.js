/**
 * Routes untuk Manajemen Proyek
 * Endpoint untuk CRUD operasi data proyek XYZ Corp
 */

const express = require('express');
const router = express.Router();

// In-memory database untuk proyek (dalam production gunakan database real)
let projects = [
  {
    id: 1,
    name: 'Mobile App Redesign',
    status: 'active',
    team: 'Product Design',
    country: 'Indonesia',
    deadline: '2026-06-30',
    progress: 65
  },
  {
    id: 2,
    name: 'Cloud Infrastructure Migration',
    status: 'active',
    team: 'DevOps',
    country: 'Singapore',
    deadline: '2026-07-15',
    progress: 45
  },
  {
    id: 3,
    name: 'Database Optimization',
    status: 'completed',
    team: 'Backend Engineering',
    country: 'USA',
    deadline: '2026-03-31',
    progress: 100
  },
  {
    id: 4,
    name: 'API Gateway Development',
    status: 'pending',
    team: 'Backend Engineering',
    country: 'India',
    deadline: '2026-08-30',
    progress: 15
  },
  {
    id: 5,
    name: 'Security Audit & Compliance',
    status: 'active',
    team: 'Security',
    country: 'Netherlands',
    deadline: '2026-05-31',
    progress: 80
  }
];

// GET /api/projects - Ambil semua proyek
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Data proyek berhasil diambil',
    count: projects.length,
    data: projects
  });
});

// POST /api/projects - Buat proyek baru
router.post('/', (req, res) => {
  const { name, team, country, deadline, progress } = req.body;
  
  // Validasi input
  if (!name || !team || !country || !deadline) {
    return res.status(400).json({
      success: false,
      message: 'Field name, team, country, dan deadline wajib diisi'
    });
  }
  
  const newProject = {
    id: projects.length > 0 ? Math.max(...projects.map(p => p.id)) + 1 : 1,
    name,
    status: 'pending',
    team,
    country,
    deadline,
    progress: progress || 0
  };
  
  projects.push(newProject);
  
  res.status(201).json({
    success: true,
    message: 'Proyek baru berhasil dibuat',
    data: newProject
  });
});

// GET /api/projects/:id - Ambil detail proyek berdasarkan ID
router.get('/:id', (req, res) => {
  const { id } = req.params;
  const project = projects.find(p => p.id === parseInt(id));
  
  if (!project) {
    return res.status(404).json({
      success: false,
      message: `Proyek dengan ID ${id} tidak ditemukan`
    });
  }
  
  res.json({
    success: true,
    message: 'Detail proyek berhasil diambil',
    data: project
  });
});

// PUT /api/projects/:id - Update proyek (status, progress, atau field lain)
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const project = projects.find(p => p.id === parseInt(id));
  
  if (!project) {
    return res.status(404).json({
      success: false,
      message: `Proyek dengan ID ${id} tidak ditemukan`
    });
  }
  
  // Update field yang diberikan
  const { name, status, team, country, deadline, progress } = req.body;
  if (name) project.name = name;
  if (status) project.status = status;
  if (team) project.team = team;
  if (country) project.country = country;
  if (deadline) project.deadline = deadline;
  if (progress !== undefined) project.progress = progress;
  
  res.json({
    success: true,
    message: 'Proyek berhasil diperbarui',
    data: project
  });
});

// DELETE /api/projects/:id - Hapus proyek
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const index = projects.findIndex(p => p.id === parseInt(id));
  
  if (index === -1) {
    return res.status(404).json({
      success: false,
      message: `Proyek dengan ID ${id} tidak ditemukan`
    });
  }
  
  const deletedProject = projects.splice(index, 1)[0];
  
  res.json({
    success: true,
    message: 'Proyek berhasil dihapus',
    data: deletedProject
  });
});

module.exports = router;
