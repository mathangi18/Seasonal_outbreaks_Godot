const { test, expect } = require('@playwright/test');
const fs = require('fs');

test('feature1: compare actual JSON to expected', async () => {
  const expected = JSON.parse(fs.readFileSync('tests/expected/feature1.json', 'utf8'));
  const actual = JSON.parse(fs.readFileSync('tests/actual/feature1.json', 'utf8'));

  // basic structural checks
  expect(actual.feature).toBe(expected.feature);

  // deep compare the numeric values with zero-tolerance for exact match here
  for (const key of Object.keys(expected.expected)) {
    expect(actual.observed).toHaveProperty(key);
    expect(actual.observed[key]).toBe(expected.expected[key]);
  }
});
