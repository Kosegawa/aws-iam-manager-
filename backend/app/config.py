from pydantic_settings import BaseSettings
from typing import List, Dict


class Settings(BaseSettings):
    # AWS設定
    aws_accounts: str = ""  # "account1:111111111111,account2:222222222222"
    aws_default_region: str = "ap-northeast-1"

    # DynamoDB設定
    dynamodb_table_name: str = "iam-audit-logs"
    dynamodb_endpoint_url: str | None = None  # ローカル開発用

    # SES設定
    ses_from_email: str = "noreply@example.com"
    ses_to_emails: str = "admin@example.com"

    # CORS設定
    cors_origins: str = "http://localhost:5173"

    class Config:
        env_file = ".env"
        case_sensitive = False

    def get_aws_accounts(self) -> Dict[str, str]:
        """AWSアカウント情報を辞書形式で取得"""
        if not self.aws_accounts:
            return {}

        accounts = {}
        for account in self.aws_accounts.split(","):
            if ":" in account:
                name, account_id = account.split(":", 1)
                accounts[name.strip()] = account_id.strip()
        return accounts

    def get_cors_origins(self) -> List[str]:
        """CORS許可オリジンをリスト形式で取得"""
        return [origin.strip() for origin in self.cors_origins.split(",")]

    def get_ses_to_emails(self) -> List[str]:
        """SES送信先メールアドレスをリスト形式で取得"""
        return [email.strip() for email in self.ses_to_emails.split(",")]


settings = Settings()
