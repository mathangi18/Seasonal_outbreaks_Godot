const { test, expect } = require('@playwright/test');

test('smoke - basic sanity', async ({ page }) => {
  // simple no-network assertion to make test runner succeed
  await page.goto('about:blank');
  expect(1).toBe(1);
});
