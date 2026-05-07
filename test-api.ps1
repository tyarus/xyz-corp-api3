
# Test POST endpoint
$response = Invoke-WebRequest -Uri 'http://localhost:3000/api/projects' -Method POST -ContentType 'application/json' -Body '{"name":"Project Alpha","team":"Engineering","country":"Indonesia","deadline":"2026-12-31","progress":0}' -UseBasicParsing
$response.Content | ConvertFrom-Json | ConvertTo-Json

# Test GET detail project
Write-Host "`n=== GET /api/projects/1 ==="
$response2 = Invoke-WebRequest -Uri 'http://localhost:3000/api/projects/1' -UseBasicParsing
$response2.Content | ConvertFrom-Json | ConvertTo-Json

# Test PUT (update project)
Write-Host "`n=== PUT /api/projects/1 ==="
$response3 = Invoke-WebRequest -Uri 'http://localhost:3000/api/projects/1' -Method PUT -ContentType 'application/json' -Body '{"status":"active","progress":50}' -UseBasicParsing
$response3.Content | ConvertFrom-Json | ConvertTo-Json

# Test GET all projects after operations
Write-Host "`n=== GET /api/projects ==="
$response4 = Invoke-WebRequest -Uri 'http://localhost:3000/api/projects' -UseBasicParsing
($response4.Content | ConvertFrom-Json).count
