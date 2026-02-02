# クイックスタートガイド

AWS IAM Managerをローカル環境で素早く起動する手順です。

## 前提条件

- Docker & Docker Compose がインストール済み
- AWS認証情報が設定済み（`~/.aws/credentials` または環境変数）

## 起動手順

### 1. 環境変数の設定

```bash
cd ~/work/aws-iam-manager/backend
cp .env.example .env
```

`.env` ファイルを編集:

```env
AWS_ACCOUNTS=myaccount:123456789012
AWS_DEFAULT_REGION=ap-northeast-1
DYNAMODB_TABLE_NAME=iam-audit-logs
SES_FROM_EMAIL=noreply@example.com
SES_TO_EMAILS=admin@example.com
CORS_ORIGINS=http://localhost:5173
```

### 2. Docker Composeで起動

```bash
cd ~/work/aws-iam-manager
docker-compose up -d
```

初回起動時は依存関係のインストールに時間がかかります。

### 3. アクセス

- フロントエンド: http://localhost:5173
- バックエンドAPI: http://localhost:8000
- API ドキュメント: http://localhost:8000/docs
- DynamoDB Local: http://localhost:8001

### 4. 動作確認

ブラウザで http://localhost:5173 を開いて以下を確認:

1. AWSアカウントが選択できること
2. IAMユーザー一覧が表示されること
3. ユーザー作成・削除ができること
4. 操作ログが記録されること

## トラブルシューティング

### バックエンドが起動しない

```bash
docker-compose logs backend
```

ログを確認して、AWS認証情報やDynamoDB接続を確認してください。

### フロントエンドが表示されない

```bash
docker-compose logs frontend
```

Node.jsの依存関係インストールが完了しているか確認してください。

### DynamoDBのテーブルが作成されない

```bash
docker-compose up -d dynamodb-init
docker-compose logs dynamodb-init
```

### 全体をリセットしたい場合

```bash
docker-compose down -v
docker-compose up -d
```

## 開発モード

ホットリロードを有効にして開発する場合:

### バックエンド開発

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### フロントエンド開発

```bash
cd frontend
npm install
npm run dev
```

## 次のステップ

- AWS環境へのデプロイ: [docs/deployment.md](docs/deployment.md)
- 詳細な機能説明: [README.md](README.md)

## 停止方法

```bash
docker-compose down
```

データを含めて削除する場合:

```bash
docker-compose down -v
```
