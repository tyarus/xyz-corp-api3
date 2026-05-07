# XYZ Corp REST API - Security Documentation

## Daftar Isi
1. [Firewall Rules](#firewall-rules)
2. [Security Headers](#security-headers)
3. [Best Practices](#best-practices)
4. [Deployment Security](#deployment-security)

---

## Firewall Rules

Tabel berikut menampilkan konfigurasi firewall yang direkomendasikan untuk deployment di Ubuntu Server:

| Port | Protocol | Source | Destination | Keterangan |
|------|----------|--------|-------------|-----------|
| 22 | TCP | SSH Admin Network | Ubuntu Server | SSH Access (Remote Management) |
| 80 | TCP | 0.0.0.0/0 | Ubuntu Server | HTTP Traffic (Public) |
| 443 | TCP | 0.0.0.0/0 | Ubuntu Server | HTTPS Traffic (Public) - Future |
| 3000 | TCP | 127.0.0.1 | Ubuntu Server | Node.js App (Internal Only) |
| 5432 | TCP | 127.0.0.1 | Ubuntu Server | PostgreSQL (Internal Only) - Future |

### Konfigurasi UFW (Uncomplicated Firewall)

```bash
# Default policy: deny incoming, allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Specific rules
sudo ufw allow ssh                    # Port 22
sudo ufw allow 80/tcp                # HTTP
sudo ufw allow 443/tcp               # HTTPS
sudo ufw enable
sudo ufw status verbose
```

**Poin Penting:**
- ✅ Port 3000 TIDAK dibuka ke publik — hanya accessible dari localhost
- ✅ Nginx di port 80 menjadi reverse proxy tunggal ke port 3000
- ✅ SSH hanya untuk administrator, dibatasi dengan IP whitelist jika memungkinkan
- ✅ Port database (5432) hanya accessible dari localhost

---

## Security Headers

Security headers yang diterapkan di Nginx reverse proxy untuk melindungi aplikasi:

### Header Configuration

```nginx
# X-Frame-Options: Mencegah clickjacking
add_header X-Frame-Options "SAMEORIGIN" always;

# X-Content-Type-Options: Mencegah MIME-sniffing
add_header X-Content-Type-Options "nosniff" always;

# X-XSS-Protection: Proteksi XSS
add_header X-XSS-Protection "1; mode=block" always;

# Content-Security-Policy: Kontrol resource loading
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;

# Referrer-Policy: Kontrol referrer information
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Permissions-Policy: Kontrol akses ke browser features
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

### Deskripsi Header

| Header | Nilai | Tujuan |
|--------|-------|--------|
| X-Frame-Options | SAMEORIGIN | Mencegah iframe embedding dari domain berbeda (clickjacking prevention) |
| X-Content-Type-Options | nosniff | Mencegah browser menginterpretasi tipe MIME yang salah |
| X-XSS-Protection | 1; mode=block | Enable XSS filter di browser, block jika detected |
| Content-Security-Policy | self restricted | Kontrol strict terhadap resource loading |
| Referrer-Policy | strict-origin-when-cross-origin | Limit referrer information yang dikirim |
| Permissions-Policy | Disabled | Disable akses ke sensitive browser APIs |

---

## Best Practices

### 1. **Application Security**

✅ **Input Validation**
- Validasi semua input dari client sebelum diproses
- Gunakan whitelist approach, bukan blacklist
- Escape output untuk mencegah XSS

✅ **Error Handling**
- Jangan expose sensitive information dalam error messages
- Log errors secara lengkap di server, tapi return generic message ke client
- Implementasi proper error status codes (400, 401, 403, 404, 500)

✅ **Rate Limiting**
- Implementasi rate limiting untuk mencegah brute force attacks
- Use libraries seperti `express-rate-limit`
- Limit login attempts, API calls per IP/User

✅ **Authentication & Authorization**
- Implementasi JWT (JSON Web Tokens) untuk stateless auth
- Store tokens di httpOnly cookies, bukan localStorage
- Validate tokens di setiap request
- Implement proper role-based access control (RBAC)

### 2. **Network Security**

✅ **HTTPS/TLS**
- Wajib gunakan HTTPS di production
- Obtain SSL certificate dari Let's Encrypt (free)
- Configure redirect dari HTTP ke HTTPS

✅ **Reverse Proxy (Nginx)**
- Hide internal IP dan port dari public
- Implement load balancing jika multiple instances
- Cache responses untuk reduce backend load

✅ **CORS Configuration**
- Restrict CORS origin ke trusted domains
- Jangan gunakan `*` di production
- Specify allowed methods dan headers

### 3. **Infrastructure Security**

✅ **Process Manager (PM2)**
- Jalankan aplikasi bukan sebagai root
- Implement health checks
- Auto-restart jika process crashes
- Limit memory dan CPU per process

✅ **System Hardening**
- Keep OS dan dependencies updated
- Disable unnecessary services
- Configure fail2ban untuk prevent brute force
- Use SSH keys, disable password auth
- Implement monitoring dan alerting

✅ **Data Protection**
- Implement data encryption at rest (untuk database)
- Use environment variables untuk sensitive data
- Implement proper logging tanpa sensitive data
- Backup data regularly

### 4. **Monitoring & Logging**

✅ **Centralized Logging**
- Log semua HTTP requests dengan timestamp, method, path, status, response time
- Log errors dengan stack traces
- Implement log rotation untuk manage disk space
- Use structured logging format (JSON)

✅ **Monitoring Metrics**
- Monitor CPU, memory, disk usage
- Track application performance metrics (response time, error rate)
- Set up alerts untuk anomalies
- Implement health check endpoints

✅ **Security Auditing**
- Log authentication attempts
- Track permission changes
- Audit API access patterns
- Review logs regularly untuk suspicious activity

---

## Deployment Security Checklist

### Pre-Deployment
- [ ] All dependencies updated to latest secure versions
- [ ] No hardcoded credentials dalam code
- [ ] Environment variables configured properly
- [ ] SSL certificate obtained
- [ ] Database encryption implemented
- [ ] Backup strategy defined

### Deployment
- [ ] Application tidak run sebagai root
- [ ] Firewall rules properly configured
- [ ] Security headers configured di Nginx
- [ ] HTTPS redirect configured
- [ ] Rate limiting implemented
- [ ] Monitoring dan alerting setup
- [ ] Backup automation configured

### Post-Deployment
- [ ] Verify firewall rules
- [ ] Test security headers dengan curl
- [ ] Monitor system resources
- [ ] Review access logs
- [ ] Schedule security updates
- [ ] Conduct security assessment

---

## Testing Security

### Test Security Headers
```bash
curl -I https://xyz-corp-api.example.com
# Verify X-Frame-Options, X-Content-Type-Options, X-XSS-Protection present
```

### Test Firewall Rules
```bash
# Test dari external: port 80 should accessible
telnet xyz-corp-api.example.com 80

# Test port 3000 should NOT accessible
telnet xyz-corp-api.example.com 3000
# Should timeout atau refuse
```

### Test CORS
```bash
# Test CORS headers
curl -H "Origin: https://untrusted.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS https://xyz-corp-api.example.com/api/projects -v
```

### Test API Rate Limiting
```bash
# Rapid requests should be rate limited
for i in {1..100}; do
  curl https://xyz-corp-api.example.com/api/projects
done
```

---

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Express.js Security Best Practices](https://expressjs.com/en/advanced/best-practice-security.html)
- [Nginx Security Hardening](https://nginx.org/en/docs/http/server_names.html)
- [Node.js Security Checklist](https://nodejs.org/en/docs/guides/security/)

---

**Last Updated:** 2026-05-07  
**Maintained By:** XYZ Corp Engineering Team
