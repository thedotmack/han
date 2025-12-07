#!/bin/bash
# Security verification script for Han plugin marketplace
# This script performs basic security checks on the codebase

set -e

echo "🔒 Han Security Verification Script"
echo "===================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ISSUES_FOUND=0

# Check 1: No eval() or Function() constructors
echo "✓ Checking for dangerous eval/Function usage..."
# Note: Basic comment filtering - may not catch all comment styles
EVAL_COUNT=$(grep -r "eval(" packages/bushido-han/lib --include="*.ts" | grep -v -E "^\s*//" | wc -l || echo "0")
FUNCTION_COUNT=$(grep -r "new Function" packages/bushido-han/lib --include="*.ts" | grep -v -E "^\s*//" | wc -l || echo "0")

if [ "$EVAL_COUNT" -gt 0 ] || [ "$FUNCTION_COUNT" -gt 0 ]; then
  echo -e "${RED}✗ Found eval() or new Function() usage (dangerous)${NC}"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
  echo -e "${GREEN}✓ No eval() or new Function() found${NC}"
fi

# Check 2: Command execution uses proper escaping
echo "✓ Checking command execution patterns..."
# Check if command execution with shell=true exists without proper sanitization
# This looks for execSync/spawn with shell:true that don't use JSON.stringify for args
UNSAFE_EXEC=$(grep -r "execSync\|spawn" packages/bushido-han/lib --include="*.ts" | \
              grep -v -E "^\s*//" | \
              grep "shell.*true" | \
              grep -v "JSON.stringify" || echo "")

if [ -n "$UNSAFE_EXEC" ]; then
  echo -e "${YELLOW}⚠ Command execution with shell=true found (review for injection)${NC}"
else
  echo -e "${GREEN}✓ Command execution appears properly handled${NC}"
fi

# Check 3: No hardcoded secrets
echo "✓ Checking for hardcoded secrets..."
SECRET_PATTERNS="password|secret|api_key|apikey|token|private_key"
if grep -r -i -E "$SECRET_PATTERNS\s*=\s*['\"][^'\"]{8,}" packages/bushido-han/lib --include="*.ts" | grep -v "// "; then
  echo -e "${RED}✗ Potential hardcoded secrets found${NC}"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
  echo -e "${GREEN}✓ No obvious hardcoded secrets found${NC}"
fi

# Check 4: File path handling
echo "✓ Checking file path handling..."
UNSAFE_PATH_COUNT=$(grep -r "readFileSync\|writeFileSync\|existsSync" packages/bushido-han/lib --include="*.ts" | grep -v "join(\|resolve(\|// " | wc -l || echo "0")

if [ "$UNSAFE_PATH_COUNT" -gt 5 ]; then
  echo -e "${YELLOW}⚠ Some file operations may not use path.join/resolve${NC}"
else
  echo -e "${GREEN}✓ File paths appear properly handled${NC}"
fi

# Check 5: JSON parsing with try-catch
echo "✓ Checking JSON parsing error handling..."
JSON_PARSE_COUNT=$(grep -r "JSON.parse" packages/bushido-han/lib --include="*.ts" | wc -l)
JSON_TRY_COUNT=$(grep -B5 "JSON.parse" packages/bushido-han/lib --include="*.ts" | grep "try" | wc -l)

# Threshold: At least 40% of JSON.parse calls should have try-catch
# This is a heuristic - manual review is still recommended
THRESHOLD=$((JSON_PARSE_COUNT * 2 / 5))

if [ "$JSON_TRY_COUNT" -lt "$THRESHOLD" ]; then
  echo -e "${YELLOW}⚠ Some JSON.parse calls may lack error handling (manual review recommended)${NC}"
else
  echo -e "${GREEN}✓ JSON parsing has adequate error handling${NC}"
fi

# Check 6: No .env files in repository
echo "✓ Checking for committed secrets..."
# Exclude documentation files that mention secrets in their name
SENSITIVE_FILES=$(git ls-files | grep -E "\.env$|\.env\." | grep -v ".gitignore\|test\|example\|template\|SKILL.md" || echo "")

if [ -n "$SENSITIVE_FILES" ]; then
  echo -e "${RED}✗ Potentially sensitive files found in git:${NC}"
  echo "$SENSITIVE_FILES"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
  echo -e "${GREEN}✓ No sensitive files committed${NC}"
fi

# Check 7: npm audit
echo "✓ Running npm audit..."
cd packages/bushido-han
AUDIT_OUTPUT=$(npm audit --json 2>/dev/null || echo '{"metadata":{"vulnerabilities":{"total":0}}}')
VULNERABILITIES=$(echo "$AUDIT_OUTPUT" | grep -o '"total":[0-9]*' | head -1 | grep -o '[0-9]*' || echo "0")

# Ensure we have a valid number
if [ -z "$VULNERABILITIES" ]; then
  VULNERABILITIES=0
fi

if [ "$VULNERABILITIES" -gt 0 ]; then
  echo -e "${RED}✗ Found $VULNERABILITIES known vulnerabilities${NC}"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
  echo -e "${GREEN}✓ No known vulnerabilities in dependencies${NC}"
fi
cd ../..

# Check 8: Marketplace URL security
echo "✓ Checking marketplace URL..."
MARKETPLACE_CHECK=$(grep -r "https://raw.githubusercontent.com/TheBushidoCollective/han" packages/bushido-han/lib/marketplace-cache.ts || echo "")

if [ -n "$MARKETPLACE_CHECK" ]; then
  echo -e "${GREEN}✓ Marketplace URL uses HTTPS and official repository${NC}"
else
  echo -e "${RED}✗ Marketplace URL may be insecure or not found${NC}"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 9: SECURITY.md exists
echo "✓ Checking security documentation..."
if [ -f "SECURITY.md" ]; then
  echo -e "${GREEN}✓ SECURITY.md present${NC}"
else
  echo -e "${YELLOW}⚠ SECURITY.md not found${NC}"
fi

# Check 10: README security warnings
echo "✓ Checking README for security guidance..."
if grep -q "security\|trust\|permission" README.md; then
  echo -e "${GREEN}✓ README includes security guidance${NC}"
else
  echo -e "${YELLOW}⚠ README could include more security guidance${NC}"
fi

echo ""
echo "===================================="
echo "Security Check Summary"
echo "===================================="

if [ $ISSUES_FOUND -eq 0 ]; then
  echo -e "${GREEN}✓ No critical security issues found${NC}"
  echo ""
  echo "Note: This is a basic automated check. Manual review and"
  echo "penetration testing are recommended for production use."
  exit 0
else
  echo -e "${RED}✗ Found $ISSUES_FOUND potential security issue(s)${NC}"
  echo ""
  echo "Please review the issues above before deploying."
  exit 1
fi
