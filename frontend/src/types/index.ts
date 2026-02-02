export interface AWSAccount {
  name: string;
  account_id: string;
}

export interface IAMUser {
  username: string;
  user_id: string;
  arn: string;
  create_date: string;
  password_last_used?: string;
}

export interface CreateUserRequest {
  username: string;
  send_notification: boolean;
}

export interface AuditLog {
  operation_id: string;
  timestamp: string;
  operator_ip: string;
  action: string;
  target_user?: string;
  aws_account: string;
  account_id: string;
  details: Record<string, any>;
  status: string;
  error_message?: string;
}
