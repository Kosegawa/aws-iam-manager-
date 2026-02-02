#!/bin/bash

# AWS IAM Manager - 実装検証スクリプト

echo "=========================================="
echo "AWS IAM Manager - Implementation Validation"
echo "=========================================="
echo ""

# 色の定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ (missing)"
        return 1
    fi
}

ERRORS=0

echo "1. プロジェクト構造チェック"
echo "----------------------------"

# バックエンド
check_dir "backend" || ((ERRORS++))
check_dir "backend/app" || ((ERRORS++))
check_dir "backend/app/api" || ((ERRORS++))
check_dir "backend/app/models" || ((ERRORS++))
check_dir "backend/app/services" || ((ERRORS++))

# フロントエンド
check_dir "frontend" || ((ERRORS++))
check_dir "frontend/src" || ((ERRORS++))
check_dir "frontend/src/components" || ((ERRORS++))
check_dir "frontend/src/services" || ((ERRORS++))
check_dir "frontend/src/types" || ((ERRORS++))

# インフラストラクチャ
check_dir "infrastructure" || ((ERRORS++))
check_dir "docs" || ((ERRORS++))

echo ""
echo "2. バックエンドファイルチェック"
echo "--------------------------------"

check_file "backend/app/main.py" || ((ERRORS++))
check_file "backend/app/config.py" || ((ERRORS++))
check_file "backend/app/api/routes.py" || ((ERRORS++))
check_file "backend/app/models/schemas.py" || ((ERRORS++))
check_file "backend/app/services/iam.py" || ((ERRORS++))
check_file "backend/app/services/dynamodb.py" || ((ERRORS++))
check_file "backend/app/services/ses.py" || ((ERRORS++))
check_file "backend/requirements.txt" || ((ERRORS++))
check_file "backend/Dockerfile" || ((ERRORS++))
check_file "backend/.env.example" || ((ERRORS++))

echo ""
echo "3. フロントエンドファイルチェック"
echo "----------------------------------"

check_file "frontend/src/main.tsx" || ((ERRORS++))
check_file "frontend/src/App.tsx" || ((ERRORS++))
check_file "frontend/src/components/AccountSelector.tsx" || ((ERRORS++))
check_file "frontend/src/components/UserList.tsx" || ((ERRORS++))
check_file "frontend/src/components/CreateUserModal.tsx" || ((ERRORS++))
check_file "frontend/src/components/AuditLogViewer.tsx" || ((ERRORS++))
check_file "frontend/src/services/api.ts" || ((ERRORS++))
check_file "frontend/src/types/index.ts" || ((ERRORS++))
check_file "frontend/package.json" || ((ERRORS++))
check_file "frontend/tsconfig.json" || ((ERRORS++))
check_file "frontend/vite.config.ts" || ((ERRORS++))
check_file "frontend/index.html" || ((ERRORS++))
check_file "frontend/Dockerfile" || ((ERRORS++))

echo ""
echo "4. インフラストラクチャファイルチェック"
echo "---------------------------------------"

check_file "infrastructure/provider.tf" || ((ERRORS++))
check_file "infrastructure/variables.tf" || ((ERRORS++))
check_file "infrastructure/outputs.tf" || ((ERRORS++))
check_file "infrastructure/dynamodb.tf" || ((ERRORS++))
check_file "infrastructure/iam.tf" || ((ERRORS++))
check_file "infrastructure/ecs.tf" || ((ERRORS++))

echo ""
echo "5. その他のファイルチェック"
echo "---------------------------"

check_file "docker-compose.yml" || ((ERRORS++))
check_file ".gitignore" || ((ERRORS++))
check_file "README.md" || ((ERRORS++))
check_file "QUICKSTART.md" || ((ERRORS++))
check_file "IMPLEMENTATION_SUMMARY.md" || ((ERRORS++))
check_file "docs/deployment.md" || ((ERRORS++))

echo ""
echo "6. コード行数"
echo "-------------"

if command -v wc &> /dev/null; then
    BACKEND_LINES=$(find backend/app -name "*.py" -type f -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
    FRONTEND_LINES=$(find frontend/src -name "*.ts" -o -name "*.tsx" -type f 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
    INFRA_LINES=$(find infrastructure -name "*.tf" -type f -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')

    echo "Backend (Python):        ${BACKEND_LINES} lines"
    echo "Frontend (TypeScript):   ${FRONTEND_LINES} lines"
    echo "Infrastructure (Terraform): ${INFRA_LINES} lines"
fi

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ すべてのファイルが正常に作成されています${NC}"
    echo ""
    echo "次のステップ:"
    echo "1. README.mdまたはQUICKSTART.mdを確認"
    echo "2. docker-compose up -d でローカル環境を起動"
    echo "3. http://localhost:5173 にアクセス"
else
    echo -e "${RED}✗ $ERRORS 個のエラーが見つかりました${NC}"
fi
echo "=========================================="
