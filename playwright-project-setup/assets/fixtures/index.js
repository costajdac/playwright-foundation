const { test: base, expect } = require('@playwright/test');

// Extend this with project-specific fixtures as needed — e.g. an
// authenticated-page fixture, or test-data setup/teardown for records
// your tests create. Keep fixtures here rather than duplicating
// setup/teardown logic across individual spec files.
const test = base.extend({
  // example: myFixture: async ({ page }, use) => { ...setup...; await use(x); ...teardown... },
});

module.exports = { test, expect };