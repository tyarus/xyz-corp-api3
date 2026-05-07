# XYZ Corp REST API

REST API terpusat untuk manajemen proyek XYZ Corp dengan lebih dari 1.200 karyawan yang tersebar di 8 negara. API ini memungkinkan tim engineering, product, dan QA untuk mengakses dan memperbarui data proyek secara konsisten dari mana saja.

## 📋 Daftar Isi

- [Fitur Utama](#fitur-utama)
- [Requirement Sistem](#requirement-sistem)
- [Instalasi & Setup](#instalasi--setup)
- [Menjalankan Server](#menjalankan-server)
- [API Endpoints](#api-endpoints)
- [Contoh Request](#contoh-request)
- [Struktur Proyek](#struktur-proyek)
- [Seed Data](#seed-data)

## ✨ Fitur Utama

- ✅ REST API lengkap dengan CRUD operations
- ✅ Health check endpoint untuk monitoring
- ✅ Statistik real-time tentang proyek
- ✅ CORS support untuk cross-origin requests
- ✅ HTTP request logging dengan Morgan
- ✅ Custom logger middleware
- ✅ Error handling yang komprehensif
- ✅ Environment configuration dengan dotenv

## 🔧 Requirement Sistem

- **Node.js**: v16.0.0 atau lebih tinggi
- **npm**: v8.0.0 atau lebih tinggi
- **OS**: Linux, macOS, atau Windows

## 🚀 Instalasi & Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd xyz-corp-api
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Setup Environment File
```bash
cp .env.example .env
```

Edit file `.env` sesuai kebutuhan (default sudah sesuai untuk development):
```
PORT=3000
NODE_ENV=development
API_VERSION=1.0.0
API_NAME=XYZ Corp REST API
CORS_ORIGIN=*
```

## ▶️ Menjalankan Server

### Mode Development
```bash
npm start
```

atau 

```bash
node src/app.js
```

Server akan berjalan di `http://localhost:3000`

## 📡 API Endpoints

### Health Check & Info

```
GET /
```
Response:
```json
{
  "success": true,
  "message": "XYZ Corp REST API is running",
  "version": "1.0.0",
  "endpoints": { ... }
}
```

### Projects Endpoints

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/projects` | Ambil semua proyek |
| POST | `/api/projects` | Buat proyek baru |
| GET | `/api/projects/:id` | Ambil detail proyek |
| PUT | `/api/projects/:id` | Update proyek |
| DELETE | `/api/projects/:id` | Hapus proyek |

### Employees Endpoints

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/employees` | Ambil semua karyawan |
| GET | `/api/employees/:id` | Ambil detail karyawan |

### Statistics Endpoints

```
GET /api/stats
```

Menampilkan statistik keseluruhan proyek:
- Total proyek
- Jumlah proyek aktif, selesai, dan pending
- Progress rata-rata
- Breakdown berdasarkan status dan progress

## 📝 Contoh Request

### 1. Health Check
```bash
curl -s http://localhost:3000/ | python3 -m json.tool
```

### 2. Ambil Semua Proyek
```bash
curl -s http://localhost:3000/api/projects | python3 -m json.tool
```

### 3. Buat Proyek Baru
```bash
curl -s -X POST http://localhost:3000/api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Project Alpha",
    "team": "Engineering",
    "country": "Indonesia",
    "deadline": "2026-12-31",
    "progress": 0
  }' | python3 -m json.tool
```

### 4. Ambil Detail Proyek (ID=1)
```bash
curl -s http://localhost:3000/api/projects/1 | python3 -m json.tool
```

### 5. Update Proyek
```bash
curl -s -X PUT http://localhost:3000/api/projects/1 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "active",
    "progress": 50
  }' | python3 -m json.tool
```

### 6. Hapus Proyek
```bash
curl -s -X DELETE http://localhost:3000/api/projects/1 | python3 -m json.tool
```

### 7. Ambil Semua Karyawan
```bash
curl -s http://localhost:3000/api/employees | python3 -m json.tool
```

### 8. Ambil Statistik
```bash
curl -s http://localhost:3000/api/stats | python3 -m json.tool
```

## 📁 Struktur Proyek

```
xyz-corp-api/
├── src/
│   ├── routes/
│   │   ├── projects.js      # Routes untuk CRUD proyek
│   │   └── employees.js     # Routes untuk data karyawan
│   ├── middleware/
│   │   └── logger.js        # Custom logging middleware
│   └── app.js               # Main application file
├── package.json             # Dependencies
├── .env.example             # Environment variables template
└── README.md                # File ini
```

## 💾 Seed Data

### Proyek (5 items)
1. Mobile App Redesign - Active (Indonesia, 65% progress)
2. Cloud Infrastructure Migration - Active (Singapore, 45% progress)
3. Database Optimization - Completed (USA, 100% progress)
4. API Gateway Development - Pending (India, 15% progress)
5. Security Audit & Compliance - Active (Netherlands, 80% progress)

### Karyawan (5 items)
1. Bambang Sutrisno - Backend Engineer (Indonesia, WIB)
2. Sarah Lee - Product Manager (Singapore, SGT)
3. Michael Johnson - DevOps Engineer (USA, EST)
4. Rajesh Patel - Frontend Engineer (India, IST)
5. Anna Mueller - Security Specialist (Netherlands, CET)

## 🔐 Security & Best Practices

- CORS diatur untuk allow cross-origin requests
- Semua HTTP requests di-log dengan Morgan
- Custom logger mencatat timestamp, method, URL, status code, dan response time
- Error handling yang proper untuk semua skenario
- Validasi input pada endpoint POST dan PUT
- Status codes yang sesuai (201 untuk create, 404 untuk not found, dll)

## 🚢 Deployment

Untuk production deployment, ikuti langkah di file DEPLOYMENT_GUIDE.md

## 📞 Support

Hubungi XYZ Corp Engineering Team untuk bantuan lebih lanjut.

---

**Version**: 1.0.0  
**Last Updated**: 2026-05-07
