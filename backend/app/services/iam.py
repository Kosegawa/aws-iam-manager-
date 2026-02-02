import boto3
from typing import List, Optional
from botocore.exceptions import ClientError
from ..models.schemas import IAMUser
from ..config import settings


class IAMService:
    def __init__(self):
        """IAMクライアントを初期化"""
        self.region = settings.aws_default_region
        self.accounts = settings.get_aws_accounts()

    def _get_iam_client(self, account_name: str):
        """指定されたアカウントのIAMクライアントを取得"""
        if account_name not in self.accounts:
            raise ValueError(f"Unknown AWS account: {account_name}")

        # 本番環境では、ここでsts:AssumeRoleを使用して別アカウントにアクセス
        # ローカル開発では、デフォルト認証を使用
        # account_id = self.accounts[account_name]

        return boto3.client("iam", region_name=self.region)

    def list_users(self, account_name: str) -> List[IAMUser]:
        """IAMユーザー一覧を取得"""
        client = self._get_iam_client(account_name)

        users = []
        paginator = client.get_paginator("list_users")

        for page in paginator.paginate():
            for user in page["Users"]:
                users.append(IAMUser(
                    username=user["UserName"],
                    user_id=user["UserId"],
                    arn=user["Arn"],
                    create_date=user["CreateDate"],
                    password_last_used=user.get("PasswordLastUsed")
                ))

        return users

    def get_user(self, account_name: str, username: str) -> Optional[IAMUser]:
        """特定のIAMユーザーを取得"""
        client = self._get_iam_client(account_name)

        try:
            response = client.get_user(UserName=username)
            user = response["User"]

            return IAMUser(
                username=user["UserName"],
                user_id=user["UserId"],
                arn=user["Arn"],
                create_date=user["CreateDate"],
                password_last_used=user.get("PasswordLastUsed")
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "NoSuchEntity":
                return None
            raise

    def create_user(self, account_name: str, username: str) -> IAMUser:
        """IAMユーザーを作成"""
        client = self._get_iam_client(account_name)

        response = client.create_user(UserName=username)
        user = response["User"]

        return IAMUser(
            username=user["UserName"],
            user_id=user["UserId"],
            arn=user["Arn"],
            create_date=user["CreateDate"],
            password_last_used=None
        )

    def delete_user(self, account_name: str, username: str) -> bool:
        """IAMユーザーを削除"""
        client = self._get_iam_client(account_name)

        try:
            # ユーザーに紐づくリソースを削除
            # 1. アクセスキーを削除
            access_keys = client.list_access_keys(UserName=username)
            for key in access_keys.get("AccessKeyMetadata", []):
                client.delete_access_key(
                    UserName=username,
                    AccessKeyId=key["AccessKeyId"]
                )

            # 2. ログインプロファイルを削除（存在する場合）
            try:
                client.delete_login_profile(UserName=username)
            except ClientError as e:
                if e.response["Error"]["Code"] != "NoSuchEntity":
                    raise

            # 3. アタッチされたポリシーをデタッチ
            attached_policies = client.list_attached_user_policies(UserName=username)
            for policy in attached_policies.get("AttachedPolicies", []):
                client.detach_user_policy(
                    UserName=username,
                    PolicyArn=policy["PolicyArn"]
                )

            # 4. インラインポリシーを削除
            inline_policies = client.list_user_policies(UserName=username)
            for policy_name in inline_policies.get("PolicyNames", []):
                client.delete_user_policy(
                    UserName=username,
                    PolicyName=policy_name
                )

            # 5. グループから削除
            groups = client.list_groups_for_user(UserName=username)
            for group in groups.get("Groups", []):
                client.remove_user_from_group(
                    UserName=username,
                    GroupName=group["GroupName"]
                )

            # 6. ユーザーを削除
            client.delete_user(UserName=username)
            return True

        except ClientError as e:
            if e.response["Error"]["Code"] == "NoSuchEntity":
                return False
            raise
