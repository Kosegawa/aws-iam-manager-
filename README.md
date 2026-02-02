# AWS IAM Manager

複数のAWSアカウントのIAMユーザーを一元管理するWebアプリケーション

## 機能

- 複数AWSアカウントのIAMユーザーを一元管理
- IAMユーザーの作成・削除
- すべての操作をDynamoDBに記録
- 操作時にメール通知（AWS SES）
- Material-UIを使用したモダンなUI

## 技術スタック

### フロントエンド
- React 18
- TypeScript
- Vite
- Material-UI (MUI)
- MUI X Data Grid
- Axios

### バックエンド
- Python 3.11
- FastAPI
- boto3（AWS SDK）
- Pydantic

### インフラストラクチャ
- AWS ECS/Fargate
- AWS DynamoDB
- AWS SES
- Application Load Balancer
- Docker

## プロジェクト構造

```
aws-iam-manager/
├── frontend/           # Reactフロントエンド
├── backend/            # FastAPIバックエンド
├── infrastructure/     # Terraformコード
├── docker-compose.yml  # ローカル開発環境
└── README.md
```

## ローカル開発環境のセットアップ

### 前提条件

- Docker & Docker Compose
- Node.js 18以上（フロントエンド開発用）
- Python 3.11以上（バックエンド開発用）
- AWS認証情報（実際のAWSアカウントにアクセスする場合）

### 1. リポジトリのクローン

```bash
cd ~/work/aws-iam-manager
```

### 2. 環境変数の設定

```bash
cd backend
cp .env.example .env
# .envファイルを編集して適切な値を設定
```

### 3. Docker Composeで起動

```bash
cd ..
docker-compose up -d
```

起動するサービス:
- `frontend`: http://localhost:5173
- `backend`: http://localhost:8000
- `backend API docs`: http://localhost:8000/docs
- `dynamodb-local`: http://localhost:8001

### 4. フロントエンド開発（ホットリロード）

```bash
cd frontend
npm install
npm run dev
```

### 5. バックエンド開発（ホットリロード）

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## AWS環境へのデプロイ

詳細は [docs/deployment.md](docs/deployment.md) を参照してください。

### 概要

1. DynamoDBテーブルの作成
2. IAMロールの作成
3. Dockerイメージのビルド & プッシュ
4. ECS/Fargateへのデプロイ

### Terraformを使用したデプロイ

```bash
cd infrastructure

# 初期化
terraform init

# 変数ファイルの作成
cat > terraform.tfvars <<EOF
environment         = "production"
vpc_id              = "vpc-xxxxx"
private_subnets     = ["subnet-xxxxx", "subnet-yyyyy"]
backend_image       = "xxxxx.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-backend"
frontend_image      = "xxxxx.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-frontend"
aws_accounts        = "account1:111111111111,account2:222222222222"
ses_from_email      = "noreply@example.com"
ses_to_emails       = "admin@example.com"
domain_name         = "iam-manager.example.com"
acm_certificate_arn = "arn:aws:acm:ap-northeast-1:xxxxx:certificate/xxxxx"
EOF

# プランの確認
terraform plan

# 適用
terraform apply
```

## API仕様

詳細なAPI仕様は http://localhost:8000/docs で確認できます。

### 主要エンドポイント

- `GET /api/accounts` - AWSアカウント一覧
- `GET /api/accounts/{account_name}/users` - IAMユーザー一覧
- `POST /api/accounts/{account_name}/users` - IAMユーザー作成
- `DELETE /api/accounts/{account_name}/users/{username}` - IAMユーザー削除
- `GET /api/logs` - 操作ログ一覧
- `GET /api/health` - ヘルスチェック

## セキュリティ考慮事項

1. **CORS設定**: 環境変数で許可するオリジンを制限
2. **VPC配置**: プライベートサブネットに配置し、インターネットから隔離
3. **IAMロール**: 最小権限の原則に従った権限設定
4. **監査ログ**: すべての操作をDynamoDBに記録
5. **入力検証**: バックエンドで厳密な入力検証を実施

## マルチアカウント対応

複数のAWSアカウントを管理する場合、各アカウントにクロスアカウントロールを作成する必要があります。

### 管理対象アカウントでの設定

各管理対象アカウントで以下のロールを作成:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::MANAGER_ACCOUNT_ID:role/iam-manager-ecs-task-role"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

ロール名: `IAMManagerRole`

必要な権限:
- `iam:ListUsers`
- `iam:GetUser`
- `iam:CreateUser`
- `iam:DeleteUser`
- その他必要なIAM権限

## トラブルシューティング

### DynamoDB Localが起動しない

```bash
docker-compose down -v
docker-compose up -d dynamodb-local dynamodb-init
```

### バックエンドがDynamoDBに接続できない

環境変数 `DYNAMODB_ENDPOINT_URL` が正しく設定されているか確認:

```bash
docker-compose logs backend
```

### フロントエンドがバックエンドに接続できない

Viteのプロキシ設定を確認: `frontend/vite.config.ts`

## ライセンス

MIT License

## 作者

Your Name

## 貢献

Issue、Pull Requestを歓迎します。
