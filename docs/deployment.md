# デプロイメントガイド

AWS環境へのデプロイ手順を説明します。

## 前提条件

- AWS CLI設定済み
- Terraform 1.0以上
- Docker
- AWS ECRへのアクセス権限
- 以下のAWSリソースの作成権限:
  - ECS/Fargate
  - DynamoDB
  - IAM
  - VPC/ALB
  - SES

## デプロイ手順

### 1. AWS ECRリポジトリの作成

```bash
# バックエンド用リポジトリ
aws ecr create-repository \
  --repository-name iam-manager-backend \
  --region ap-northeast-1

# フロントエンド用リポジトリ
aws ecr create-repository \
  --repository-name iam-manager-frontend \
  --region ap-northeast-1
```

### 2. Dockerイメージのビルドとプッシュ

```bash
# ECRにログイン
aws ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin \
  ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com

# バックエンドイメージのビルド
cd backend
docker build -t iam-manager-backend:latest .
docker tag iam-manager-backend:latest \
  ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-backend:latest
docker push ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-backend:latest

# フロントエンドイメージのビルド
cd ../frontend
docker build -t iam-manager-frontend:latest .
docker tag iam-manager-frontend:latest \
  ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-frontend:latest
docker push ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-frontend:latest
```

### 3. SESの設定

```bash
# 送信元メールアドレスの検証
aws ses verify-email-identity \
  --email-address noreply@example.com \
  --region ap-northeast-1

# 受信先メールアドレスの検証（サンドボックス環境の場合）
aws ses verify-email-identity \
  --email-address admin@example.com \
  --region ap-northeast-1
```

本番環境ではSESをサンドボックスモードから移動させる必要があります:
https://console.aws.amazon.com/ses/

### 4. VPCとサブネットの準備

既存のVPCとプライベートサブネットを使用するか、新規作成します。

```bash
# VPC IDを取得
aws ec2 describe-vpcs --region ap-northeast-1

# プライベートサブネットIDを取得
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-xxxxx" \
  --region ap-northeast-1
```

### 5. ACM証明書の作成

HTTPS接続用のSSL/TLS証明書を作成します。

```bash
# 証明書のリクエスト
aws acm request-certificate \
  --domain-name iam-manager.example.com \
  --validation-method DNS \
  --region ap-northeast-1

# 証明書のARNを取得
aws acm list-certificates --region ap-northeast-1
```

DNS検証を完了させる必要があります。

### 6. Terraformの設定

```bash
cd ../infrastructure

# terraform.tfvarsファイルの作成
cat > terraform.tfvars <<EOF
environment         = "production"
aws_region          = "ap-northeast-1"
vpc_id              = "vpc-xxxxx"
private_subnets     = ["subnet-xxxxx", "subnet-yyyyy"]
allowed_cidr_blocks = ["10.0.0.0/8"]

backend_image       = "ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-backend"
frontend_image      = "ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-frontend"
image_tag           = "latest"

aws_accounts        = "production:111111111111,staging:222222222222"
ses_from_email      = "noreply@example.com"
ses_to_emails       = "admin@example.com,security@example.com"
domain_name         = "iam-manager.example.com"
acm_certificate_arn = "arn:aws:acm:ap-northeast-1:xxxxx:certificate/xxxxx"
EOF
```

### 7. Terraformの実行

```bash
# 初期化
terraform init

# プランの確認
terraform plan

# 適用
terraform apply
```

### 8. ALBのDNS名を取得

```bash
terraform output alb_dns_name
```

この DNS名をRoute 53などで設定します。

### 9. 動作確認

```bash
# ヘルスチェック
curl https://iam-manager.example.com/api/health

# ブラウザでアクセス
open https://iam-manager.example.com
```

## クロスアカウントアクセスの設定

複数のAWSアカウントを管理する場合、各アカウントにクロスアカウントロールを作成します。

### 管理対象アカウントでの作業

1. 各管理対象アカウントにログイン
2. 以下のIAMロールを作成

```bash
# assume-role-policy.json
cat > assume-role-policy.json <<EOF
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
EOF

# ロールの作成
aws iam create-role \
  --role-name IAMManagerRole \
  --assume-role-policy-document file://assume-role-policy.json

# ポリシーのアタッチ
aws iam attach-role-policy \
  --role-name IAMManagerRole \
  --policy-arn arn:aws:iam::aws:policy/IAMReadOnlyAccess

# カスタムポリシーの作成（IAMユーザー作成・削除用）
cat > iam-write-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateUser",
        "iam:DeleteUser",
        "iam:ListAccessKeys",
        "iam:DeleteAccessKey",
        "iam:DeleteLoginProfile",
        "iam:ListAttachedUserPolicies",
        "iam:DetachUserPolicy",
        "iam:ListUserPolicies",
        "iam:DeleteUserPolicy",
        "iam:ListGroupsForUser",
        "iam:RemoveUserFromGroup"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name IAMManagerRole \
  --policy-name IAMWritePolicy \
  --policy-document file://iam-write-policy.json
```

## 更新・再デプロイ

### アプリケーションコードの更新

```bash
# 新しいイメージをビルド & プッシュ（バージョンタグ付き）
docker build -t iam-manager-backend:v1.1.0 ./backend
docker tag iam-manager-backend:v1.1.0 \
  ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-backend:v1.1.0
docker push ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/iam-manager-backend:v1.1.0

# ECSサービスの更新
aws ecs update-service \
  --cluster iam-manager-cluster \
  --service iam-manager-service \
  --force-new-deployment \
  --region ap-northeast-1
```

### インフラストラクチャの更新

```bash
cd infrastructure

# terraform.tfvarsを更新
vim terraform.tfvars

# 変更内容の確認
terraform plan

# 適用
terraform apply
```

## モニタリング

### CloudWatch Logs

```bash
# ログの確認
aws logs tail /ecs/iam-manager --follow --region ap-northeast-1
```

### ECSサービスの状態確認

```bash
aws ecs describe-services \
  --cluster iam-manager-cluster \
  --services iam-manager-service \
  --region ap-northeast-1
```

### DynamoDBのメトリクス

CloudWatchコンソールでDynamoDBテーブルのメトリクスを確認:
- 読み込み/書き込みキャパシティ
- エラー率
- レイテンシ

## バックアップとリストア

### DynamoDBのバックアップ

ポイントインタイムリカバリが有効になっているため、過去35日間のデータを復元できます。

手動バックアップ:

```bash
aws dynamodb create-backup \
  --table-name iam-audit-logs \
  --backup-name iam-audit-logs-backup-$(date +%Y%m%d) \
  --region ap-northeast-1
```

### リストア

```bash
aws dynamodb restore-table-from-backup \
  --target-table-name iam-audit-logs-restored \
  --backup-arn arn:aws:dynamodb:ap-northeast-1:xxxxx:table/iam-audit-logs/backup/xxxxx \
  --region ap-northeast-1
```

## トラブルシューティング

### ECSタスクが起動しない

1. CloudWatch Logsを確認
2. タスク定義のIAMロールを確認
3. セキュリティグループの設定を確認

### DynamoDBへの接続エラー

1. ECSタスクロールにDynamoDB権限があるか確認
2. VPCエンドポイントの設定を確認（プライベートサブネットの場合）

### SESメールが送信されない

1. SESがサンドボックスモードになっていないか確認
2. メールアドレスが検証済みか確認
3. ECSタスクロールにSES権限があるか確認

## セキュリティベストプラクティス

1. 定期的なセキュリティパッチの適用
2. IAM権限の最小化
3. VPCフローログの有効化
4. AWS CloudTrailの有効化
5. AWS Configによるコンプライアンスチェック
6. 定期的なアクセスログの監査

## コスト最適化

- Fargate Spotの利用検討
- DynamoDBのオンデマンドモード vs プロビジョンドモード
- ALBのアイドルタイムアウト設定
- CloudWatch Logsの保持期間設定
