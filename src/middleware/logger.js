/**
 * Custom Logger Middleware
 * Mencatat semua HTTP request dengan detail timestamp, method, URL, status code, dan response time
 */

const logger = (req, res, next) => {
  const timestamp = new Date().toISOString();
  const method = req.method;
  const url = req.originalUrl;
  
  // Catat waktu mulai request
  const startTime = Date.now();
  
  // Override res.send untuk mencatat response status
  const originalSend = res.send;
  res.send = function(data) {
    const duration = Date.now() - startTime;
    const statusCode = res.statusCode;
    
    console.log(`[${timestamp}] ${method} ${url} - Status: ${statusCode} - Duration: ${duration}ms`);
    
    // Panggil send asli
    return originalSend.call(this, data);
  };
  
  next();
};

module.exports = logger;
