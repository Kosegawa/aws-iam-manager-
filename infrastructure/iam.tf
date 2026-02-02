# ECSタスク実行ロール
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "iam-manager-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "iam-manager-ecs-task-execution-role"
    Environment = var.environment
  }
}

# ECSタスク実行ロールにAmazonECSTaskExecutionRolePolicyをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSタスクロール（アプリケーションが使用）
resource "aws_iam_role" "ecs_task_role" {
  name = "iam-manager-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "iam-manager-ecs-task-role"
    Environment = var.environment
  }
}

# IAM操作権限
resource "aws_iam_role_policy" "iam_manager_permissions" {
  name = "iam-manager-permissions"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:GetUser",
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
        ]
        Resource = "*"
      }
    ]
  })
}

# DynamoDB操作権限
resource "aws_iam_role_policy" "dynamodb_permissions" {
  name = "dynamodb-permissions"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.iam_audit_logs.arn
      }
    ]
  })
}

# SES送信権限
resource "aws_iam_role_policy" "ses_permissions" {
  name = "ses-permissions"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# クロスアカウントアクセス用のAssumeRole権限
resource "aws_iam_role_policy" "assume_role_permissions" {
  name = "assume-role-permissions"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:aws:iam::*:role/IAMManagerRole"
      }
    ]
  })
}

# 他のAWSアカウントに作成するロール（例）
# 各管理対象アカウントにこのロールを作成する必要がある
resource "aws_iam_role" "cross_account_iam_manager_role" {
  count = 0 # 必要に応じて有効化

  name = "IAMManagerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        }
      }
    ]
  })

  tags = {
    Name        = "IAMManagerRole"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "cross_account_iam_permissions" {
  count = 0 # 必要に応じて有効化

  name = "iam-manager-permissions"
  role = aws_iam_role.cross_account_iam_manager_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:GetUser",
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
        ]
        Resource = "*"
      }
    ]
  })
}
