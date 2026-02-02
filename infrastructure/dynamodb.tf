resource "aws_dynamodb_table" "iam_audit_logs" {
  name         = "iam-audit-logs"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "operation_id"
  range_key = "timestamp"

  attribute {
    name = "operation_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # ポイントインタイムリカバリを有効化
  point_in_time_recovery {
    enabled = true
  }

  # タグ
  tags = {
    Name        = "iam-audit-logs"
    Environment = var.environment
    Project     = "aws-iam-manager"
  }
}

# グローバルセカンダリインデックス（アカウント名での検索用）
resource "aws_dynamodb_table" "iam_audit_logs_gsi" {
  count = 0 # 必要に応じて有効化

  name         = "iam-audit-logs"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "operation_id"
  range_key = "timestamp"

  attribute {
    name = "operation_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "aws_account"
    type = "S"
  }

  global_secondary_index {
    name            = "AccountIndex"
    hash_key        = "aws_account"
    range_key       = "timestamp"
    projection_type = "ALL"
  }
}
