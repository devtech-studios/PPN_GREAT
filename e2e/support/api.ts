import { expect, request, type APIRequestContext } from '@playwright/test';
import { env } from './env';

export type ApiSession = { api: APIRequestContext; token: string };

export async function createApiSession(): Promise<ApiSession> {
  const api = await request.newContext({ baseURL: env.apiBaseUrl });
  const response = await api.post('/api/auth/login', {
    data: { email: env.adminEmail, password: env.adminPassword },
  });
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  expect(body.success).toBe(true);
  return { api, token: body.data.token };
}

export function authHeaders(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}`, Accept: 'application/json' };
}

export function uniqueRunId(prefix = 'PW'): string {
  return `${prefix}-${new Date().toISOString().replace(/\D/g, '').slice(0, 14)}-${Math.random().toString(36).slice(2, 7)}`;
}
