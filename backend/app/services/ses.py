import boto3
from typing import List
from botocore.exceptions import ClientError
from ..config import settings


class SESService:
    def __init__(self):
        """SESクライアントを初期化"""
        self.client = boto3.client("ses", region_name=settings.aws_default_region)
        self.from_email = settings.ses_from_email
        self.to_emails = settings.get_ses_to_emails()

    def send_user_created_notification(
        self,
        username: str,
        account_name: str,
        account_id: str,
        operator_ip: str
    ) -> bool:
        """IAMユーザー作成通知メールを送信"""
        subject = f"[AWS IAM] New User Created: {username}"

        body_text = f"""
AWS IAM User Created

Account: {account_name} ({account_id})
Username: {username}
Created by: {operator_ip}
Timestamp: {self._get_current_timestamp()}

This is an automated notification from AWS IAM Manager.
"""

        body_html = f"""
<html>
<head></head>
<body>
  <h2>AWS IAM User Created</h2>
  <table border="1" cellpadding="10">
    <tr>
      <th>Account</th>
      <td>{account_name} ({account_id})</td>
    </tr>
    <tr>
      <th>Username</th>
      <td><strong>{username}</strong></td>
    </tr>
    <tr>
      <th>Created by</th>
      <td>{operator_ip}</td>
    </tr>
    <tr>
      <th>Timestamp</th>
      <td>{self._get_current_timestamp()}</td>
    </tr>
  </table>
  <p><em>This is an automated notification from AWS IAM Manager.</em></p>
</body>
</html>
"""

        return self._send_email(subject, body_text, body_html)

    def send_user_deleted_notification(
        self,
        username: str,
        account_name: str,
        account_id: str,
        operator_ip: str
    ) -> bool:
        """IAMユーザー削除通知メールを送信"""
        subject = f"[AWS IAM] User Deleted: {username}"

        body_text = f"""
AWS IAM User Deleted

Account: {account_name} ({account_id})
Username: {username}
Deleted by: {operator_ip}
Timestamp: {self._get_current_timestamp()}

This is an automated notification from AWS IAM Manager.
"""

        body_html = f"""
<html>
<head></head>
<body>
  <h2>AWS IAM User Deleted</h2>
  <table border="1" cellpadding="10">
    <tr>
      <th>Account</th>
      <td>{account_name} ({account_id})</td>
    </tr>
    <tr>
      <th>Username</th>
      <td><strong>{username}</strong></td>
    </tr>
    <tr>
      <th>Deleted by</th>
      <td>{operator_ip}</td>
    </tr>
    <tr>
      <th>Timestamp</th>
      <td>{self._get_current_timestamp()}</td>
    </tr>
  </table>
  <p><em>This is an automated notification from AWS IAM Manager.</em></p>
</body>
</html>
"""

        return self._send_email(subject, body_text, body_html)

    def _send_email(self, subject: str, body_text: str, body_html: str) -> bool:
        """メールを送信"""
        try:
            response = self.client.send_email(
                Source=self.from_email,
                Destination={"ToAddresses": self.to_emails},
                Message={
                    "Subject": {"Data": subject, "Charset": "UTF-8"},
                    "Body": {
                        "Text": {"Data": body_text, "Charset": "UTF-8"},
                        "Html": {"Data": body_html, "Charset": "UTF-8"}
                    }
                }
            )
            return True
        except ClientError as e:
            print(f"Failed to send email: {e}")
            return False

    def _get_current_timestamp(self) -> str:
        """現在のタイムスタンプを取得"""
        from datetime import datetime
        return datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
