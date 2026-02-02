import axios from 'axios';
import { AWSAccount, IAMUser, CreateUserRequest, AuditLog } from '../types';

const API_BASE_URL = '/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const apiService = {
  // AWSアカウント関連
  async getAccounts(): Promise<AWSAccount[]> {
    const response = await api.get<AWSAccount[]>('/accounts');
    return response.data;
  },

  // IAMユーザー関連
  async getUsers(accountName: string): Promise<IAMUser[]> {
    const response = await api.get<IAMUser[]>(`/accounts/${accountName}/users`);
    return response.data;
  },

  async createUser(accountName: string, request: CreateUserRequest): Promise<IAMUser> {
    const response = await api.post<IAMUser>(`/accounts/${accountName}/users`, request);
    return response.data;
  },

  async deleteUser(accountName: string, username: string): Promise<void> {
    await api.delete(`/accounts/${accountName}/users/${username}`);
  },

  // 操作ログ関連
  async getLogs(limit: number = 100, accountName?: string): Promise<AuditLog[]> {
    const params: any = { limit };
    if (accountName) {
      params.account_name = accountName;
    }
    const response = await api.get<AuditLog[]>('/logs', { params });
    return response.data;
  },

  // ヘルスチェック
  async healthCheck(): Promise<{ status: string; timestamp: string }> {
    const response = await api.get('/health');
    return response.data;
  },
};
