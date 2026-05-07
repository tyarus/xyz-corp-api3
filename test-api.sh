#!/bin/bash

# XYZ Corp API - API Test Script
# Comprehensive testing of all endpoints

BASE_URL="http://localhost:3000"

echo "╔════════════════════════════════════════════════════════╗"
echo "║    XYZ CORP API - COMPREHENSIVE TEST SUITE             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# Function to test endpoint
test_endpoint() {
    local METHOD=$1
    local ENDPOINT=$2
    local DATA=$3
    local EXPECTED_STATUS=$4
    
    echo -n "Testing: $METHOD $ENDPOINT ... "
    
    if [ -z "$DATA" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X $METHOD "$BASE_URL$ENDPOINT")
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X $METHOD "$BASE_URL$ENDPOINT" \
            -H "Content-Type: application/json" \
            -d "$DATA")
    fi
    
    STATUS_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$STATUS_CODE" = "$EXPECTED_STATUS" ]; then
        echo -e "${GREEN}✅ PASS${NC} (Status: $STATUS_CODE)"
        ((PASS_COUNT++))
        echo "  Response: $(echo "$BODY" | head -c 80)..."
    else
        echo -e "${RED}❌ FAIL${NC} (Status: $STATUS_CODE, Expected: $EXPECTED_STATUS)"
        ((FAIL_COUNT++))
    fi
    echo ""
}

# ============================================
# TEST SUITE
# ============================================

echo "═══════════════════════════════════════════════════════"
echo "1. HEALTH CHECK ENDPOINTS"
echo "═══════════════════════════════════════════════════════"
test_endpoint "GET" "/" "" "200"
test_endpoint "GET" "/health" "" "404"  # health endpoint doesn't exist on app.js yet

echo "═══════════════════════════════════════════════════════"
echo "2. PROJECT ENDPOINTS - READ"
echo "═══════════════════════════════════════════════════════"
test_endpoint "GET" "/api/projects" "" "200"
test_endpoint "GET" "/api/projects/1" "" "200"
test_endpoint "GET" "/api/projects/999" "" "404"

echo "═══════════════════════════════════════════════════════"
echo "3. PROJECT ENDPOINTS - CREATE"
echo "═══════════════════════════════════════════════════════"
test_endpoint "POST" "/api/projects" \
    '{"name":"Test Project","team":"QA","country":"Malaysia","deadline":"2026-12-31","progress":0}' \
    "201"

echo "═══════════════════════════════════════════════════════"
echo "4. PROJECT ENDPOINTS - UPDATE"
echo "═══════════════════════════════════════════════════════"
test_endpoint "PUT" "/api/projects/1" \
    '{"status":"completed","progress":100}' \
    "200"

echo "═══════════════════════════════════════════════════════"
echo "5. PROJECT ENDPOINTS - DELETE"
echo "═══════════════════════════════════════════════════════"
test_endpoint "DELETE" "/api/projects/1" "" "200"

echo "═══════════════════════════════════════════════════════"
echo "6. EMPLOYEE ENDPOINTS"
echo "═══════════════════════════════════════════════════════"
test_endpoint "GET" "/api/employees" "" "200"
test_endpoint "GET" "/api/employees/1" "" "200"
test_endpoint "GET" "/api/employees/999" "" "404"

echo "═══════════════════════════════════════════════════════"
echo "7. STATISTICS ENDPOINTS"
echo "═══════════════════════════════════════════════════════"
test_endpoint "GET" "/api/stats" "" "200"

echo "═══════════════════════════════════════════════════════"
echo "8. ERROR HANDLING"
echo "═══════════════════════════════════════════════════════"
test_endpoint "GET" "/api/invalid" "" "404"
test_endpoint "POST" "/api/projects" \
    '{"team":"No Name","country":"Test","deadline":"2026-12-31"}' \
    "400"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║ TEST RESULTS SUMMARY                                   ║"
echo "╠════════════════════════════════════════════════════════╣"
echo "║ Passed: $PASS_COUNT"
echo "║ Failed: $FAIL_COUNT"
echo "║ Total:  $((PASS_COUNT + FAIL_COUNT))"
echo "╚════════════════════════════════════════════════════════╝"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
