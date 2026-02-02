from fastapi import APIRouter, HTTPException, Request
from typing import List, Optional
from datetime import datetime
from ..models.schemas import (
    AWSAccount, IAMUser, CreateUserRequest,
    AuditLog, HealthResponse, CreateAuditLogRequest
)
from ..services.iam import IAMService
from ..services.dynamodb import DynamoDBService
from ..services.ses import SESService
from ..config import settings

router = APIRouter()

# サービスインスタンスを初期化
iam_service = IAMService()
dynamodb_service = DynamoDBService()
ses_service = SESService()


def get_client_ip(request: Request) -> str:
    """クライアントIPアドレスを取得"""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """ヘルスチェック"""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow()
    )


@router.get("/accounts", response_model=List[AWSAccount])
async def list_accounts():
    """AWSアカウント一覧を取得"""
    accounts = settings.get_aws_accounts()
    return [
        AWSAccount(name=name, account_id=account_id)
        for name, account_id in accounts.items()
    ]


@router.get("/accounts/{account_name}/users", response_model=List[IAMUser])
async def list_users(account_name: str, request: Request):
    """IAMユーザー一覧を取得"""
    try:
        users = iam_service.list_users(account_name)

        # ログ記録
        account_id = settings.get_aws_accounts().get(account_name, "unknown")
        dynamodb_service.create_log(CreateAuditLogRequest(
            operator_ip=get_client_ip(request),
            action="list_users",
            aws_account=account_name,
            account_id=account_id,
            status="success"
        ))

        return users
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        # エラーログ記録
        account_id = settings.get_aws_accounts().get(account_name, "unknown")
        dynamodb_service.create_log(CreateAuditLogRequest(
            operator_ip=get_client_ip(request),
            action="list_users",
            aws_account=account_name,
            account_id=account_id,
            status="failed",
            error_message=str(e)
        ))
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/accounts/{account_name}/users", response_model=IAMUser)
async def create_user(
    account_name: str,
    user_request: CreateUserRequest,
    request: Request
):
    """IAMユーザーを作成"""
    try:
        # ユーザー作成
        user = iam_service.create_user(account_name, user_request.username)

        # ログ記録
        account_id = settings.get_aws_accounts().get(account_name, "unknown")
        dynamodb_service.create_log(CreateAuditLogRequest(
            operator_ip=get_client_ip(request),
            action="create_user",
            target_user=user_request.username,
            aws_account=account_name,
            account_id=account_id,
            details={"send_notification": user_request.send_notification},
            status="success"
        ))

        # メール通知送信
        if user_request.send_notification:
            ses_service.send_user_created_notification(
                username=user_request.username,
                account_name=account_name,
                account_id=account_id,
                operator_ip=get_client_ip(request)
            )

        return user
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        # エラーログ記録
        account_id = settings.get_aws_accounts().get(account_name, "unknown")
        dynamodb_service.create_log(CreateAuditLogRequest(
            operator_ip=get_client_ip(request),
            action="create_user",
            target_user=user_request.username,
            aws_account=account_name,
            account_id=account_id,
            status="failed",
            error_message=str(e)
        ))
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/accounts/{account_name}/users/{username}")
async def delete_user(account_name: str, username: str, request: Request):
    """IAMユーザーを削除"""
    try:
        # ユーザー削除
        success = iam_service.delete_user(account_name, username)

        if not success:
            raise HTTPException(status_code=404, detail=f"User {username} not found")

        # ログ記録
        account_id = settings.get_aws_accounts().get(account_name, "unknown")
        dynamodb_service.create_log(CreateAuditLogRequest(
            operator_ip=get_client_ip(request),
            action="delete_user",
            target_user=username,
            aws_account=account_name,
            account_id=account_id,
            status="success"
        ))

        # メール通知送信
        ses_service.send_user_deleted_notification(
            username=username,
            account_name=account_name,
            account_id=account_id,
            operator_ip=get_client_ip(request)
        )

        return {"message": f"User {username} deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        # エラーログ記録
        account_id = settings.get_aws_accounts().get(account_name, "unknown")
        dynamodb_service.create_log(CreateAuditLogRequest(
            operator_ip=get_client_ip(request),
            action="delete_user",
            target_user=username,
            aws_account=account_name,
            account_id=account_id,
            status="failed",
            error_message=str(e)
        ))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/logs", response_model=List[AuditLog])
async def get_logs(limit: int = 100, account_name: Optional[str] = None):
    """操作ログを取得"""
    try:
        logs = dynamodb_service.get_logs(limit=limit, account_name=account_name)
        return logs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
