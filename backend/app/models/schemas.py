from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any


class AWSAccount(BaseModel):
    """AWSアカウント情報"""
    name: str
    account_id: str


class IAMUser(BaseModel):
    """IAMユーザー情報"""
    username: str
    user_id: str
    arn: str
    create_date: datetime
    password_last_used: Optional[datetime] = None


class CreateUserRequest(BaseModel):
    """IAMユーザー作成リクエスト"""
    username: str
    send_notification: bool = True


class DeleteUserRequest(BaseModel):
    """IAMユーザー削除リクエスト（ボディは不要だがレスポンス用）"""
    pass


class AuditLog(BaseModel):
    """操作ログ"""
    operation_id: str
    timestamp: datetime
    operator_ip: str
    action: str
    target_user: Optional[str] = None
    aws_account: str
    account_id: str
    details: Dict[str, Any] = Field(default_factory=dict)
    status: str  # success, failed
    error_message: Optional[str] = None


class CreateAuditLogRequest(BaseModel):
    """操作ログ作成用の内部モデル"""
    operator_ip: str
    action: str
    target_user: Optional[str] = None
    aws_account: str
    account_id: str
    details: Dict[str, Any] = Field(default_factory=dict)
    status: str = "success"
    error_message: Optional[str] = None


class HealthResponse(BaseModel):
    """ヘルスチェックレスポンス"""
    status: str
    timestamp: datetime
