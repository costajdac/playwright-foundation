const { test, expect } = require('@playwright/test');

test.describe('Example API', () => {
  test('GET /users returns a 200 with a list', async ({ request }) => {
    const response = await request.get('/users');

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(Array.isArray(body)).toBeTruthy();
  });
});
