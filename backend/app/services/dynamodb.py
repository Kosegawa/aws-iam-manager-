import boto3
from datetime import datetime
from typing import List, Optional
from uuid import uuid4
from ..models.schemas import AuditLog, CreateAuditLogRequest
from ..config import settings


class DynamoDBService:
    def __init__(self):
        """DynamoDBクライアントを初期化"""
        kwargs = {"region_name": settings.aws_default_region}
        if settings.dynamodb_endpoint_url:
            kwargs["endpoint_url"] = settings.dynamodb_endpoint_url

        self.client = boto3.client("dynamodb", **kwargs)
        self.resource = boto3.resource("dynamodb", **kwargs)
        self.table = self.resource.Table(settings.dynamodb_table_name)

    def create_log(self, log_request: CreateAuditLogRequest) -> AuditLog:
        """操作ログを記録"""
        operation_id = str(uuid4())
        timestamp = datetime.utcnow()

        log = AuditLog(
            operation_id=operation_id,
            timestamp=timestamp,
            operator_ip=log_request.operator_ip,
            action=log_request.action,
            target_user=log_request.target_user,
            aws_account=log_request.aws_account,
            account_id=log_request.account_id,
            details=log_request.details,
            status=log_request.status,
            error_message=log_request.error_message
        )

        # DynamoDBに保存
        self.table.put_item(Item={
            "operation_id": log.operation_id,
            "timestamp": log.timestamp.isoformat(),
            "operator_ip": log.operator_ip,
            "action": log.action,
            "target_user": log.target_user,
            "aws_account": log.aws_account,
            "account_id": log.account_id,
            "details": log.details,
            "status": log.status,
            "error_message": log.error_message
        })

        return log

    def get_logs(self, limit: int = 100, account_name: Optional[str] = None) -> List[AuditLog]:
        """操作ログを取得"""
        kwargs = {
            "Limit": limit,
        }

        # アカウント名でフィルタリング
        if account_name:
            kwargs["FilterExpression"] = "aws_account = :account"
            kwargs["ExpressionAttributeValues"] = {":account": account_name}

        response = self.table.scan(**kwargs)
        items = response.get("Items", [])

        # タイムスタンプでソート（降順）
        items.sort(key=lambda x: x.get("timestamp", ""), reverse=True)

        logs = []
        for item in items:
            logs.append(AuditLog(
                operation_id=item["operation_id"],
                timestamp=datetime.fromisoformat(item["timestamp"]),
                operator_ip=item["operator_ip"],
                action=item["action"],
                target_user=item.get("target_user"),
                aws_account=item["aws_account"],
                account_id=item["account_id"],
                details=item.get("details", {}),
                status=item["status"],
                error_message=item.get("error_message")
            ))

        return logs
