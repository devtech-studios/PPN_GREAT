import { expect, test } from '@playwright/test';
import { authHeaders, createApiSession } from './support/api';
import { env } from './support/env';

test.describe('API contracts used by the web UI', () => {
  test('@smoke rejects unauthenticated access for every protected module', async ({ request }) => {
    const protectedLists = [
      '/api/customers',
      '/api/projects',
      '/api/suppliers',
      '/api/samples',
      '/api/artworks',
      '/api/containers',
      '/api/inventory/warehouses',
      '/api/delivery/rounds',
      '/api/finance/documents',
      '/api/finance/payments',
      '/api/dashboard/summary',
      '/api/reports/financial-summary',
    ];
    for (const path of protectedLists) {
      const response = await request.get(`${env.apiBaseUrl}${path}`, {
        headers: { Accept: 'application/json' },
      });
      expect(response.status(), path).toBe(401);
    }
  });

  test('all list/read contracts used by screens return success', async () => {
    const { api, token } = await createApiSession();
    const paths = [
      '/api/customers',
      '/api/projects',
      '/api/suppliers',
      '/api/samples',
      '/api/artworks',
      '/api/inventory/warehouses',
      '/api/inventory/movements',
      '/api/inventory/low-stock',
      '/api/delivery/rounds',
      '/api/finance/documents',
      '/api/finance/payments',
      '/api/dashboard/summary',
      '/api/dashboard/activities',
      '/api/dashboard/revenue-chart',
      '/api/reports/financial-summary',
      '/api/reports/operational-summary',
      '/api/reports/revenue-by-month',
      '/api/reports/profit-by-project',
    ];
    try {
      for (const path of paths) {
        const response = await api.get(path, { headers: authHeaders(token) });
        const body = await response.json();
        expect(response.ok(), `${path}: ${JSON.stringify(body)}`).toBeTruthy();
        expect(body.success, path).toBe(true);
        expect(body).toHaveProperty('data');
      }
    } finally {
      await api.dispose();
    }
  });

  test('create endpoints reject empty payloads without mutating data', async () => {
    const { api, token } = await createApiSession();
    const paths = [
      '/api/customers',
      '/api/projects',
      '/api/suppliers',
      '/api/samples',
      '/api/artworks',
      '/api/inventory/warehouses',
      '/api/delivery/rounds',
      '/api/finance/documents',
      '/api/finance/payments',
    ];
    try {
      for (const path of paths) {
        const response = await api.post(path, { headers: authHeaders(token), data: {} });
        expect(response.status(), path).toBe(422);
      }
    } finally {
      await api.dispose();
    }
  });

  test.fixme('Containers API rejects an empty create payload', async () => {
    // Known defect: POST /api/containers currently accepts {} and creates an empty container.
    // Do not execute this against a shared database until container_no/project_ids are required.
  });
});
