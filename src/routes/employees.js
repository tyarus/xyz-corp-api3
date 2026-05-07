/**
 * Routes untuk Manajemen Karyawan
 * Endpoint untuk mengambil data karyawan XYZ Corp
 */

const express = require('express');
const router = express.Router();

// In-memory database untuk karyawan (dalam production gunakan database real)
const employees = [
  {
    id: 1,
    name: 'Bambang Sutrisno',
    role: 'Backend Engineer',
    country: 'Indonesia',
    timezone: 'WIB (UTC+7)'
  },
  {
    id: 2,
    name: 'Sarah Lee',
    role: 'Product Manager',
    country: 'Singapore',
    timezone: 'SGT (UTC+8)'
  },
  {
    id: 3,
    name: 'Michael Johnson',
    role: 'DevOps Engineer',
    country: 'USA',
    timezone: 'EST (UTC-5)'
  },
  {
    id: 4,
    name: 'Rajesh Patel',
    role: 'Frontend Engineer',
    country: 'India',
    timezone: 'IST (UTC+5:30)'
  },
  {
    id: 5,
    name: 'Anna Mueller',
    role: 'Security Specialist',
    country: 'Netherlands',
    timezone: 'CET (UTC+1)'
  }
];

// GET /api/employees - Ambil semua karyawan
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Data karyawan berhasil diambil',
    count: employees.length,
    data: employees
  });
});

// GET /api/employees/:id - Ambil detail karyawan berdasarkan ID
router.get('/:id', (req, res) => {
  const { id } = req.params;
  const employee = employees.find(e => e.id === parseInt(id));
  
  if (!employee) {
    return res.status(404).json({
      success: false,
      message: `Karyawan dengan ID ${id} tidak ditemukan`
    });
  }
  
  res.json({
    success: true,
    message: 'Detail karyawan berhasil diambil',
    data: employee
  });
});

module.exports = router;
