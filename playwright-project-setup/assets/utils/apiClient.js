/**
 * Thin wrapper around Playwright's APIRequestContext for reusable API calls.
 * Use this from tests/api specs when you want shared headers/auth logic
 * instead of repeating request.get/post calls inline.
 *
 * @param {import('@playwright/test').APIRequestContext} request
 */
function createApiClient(request, { authToken } = {}) {
  const headers = authToken ? { Authorization: `Bearer ${authToken}` } : {};

  return {
    get: (url, options = {}) =>
      request.get(url, { headers: { ...headers, ...options.headers }, ...options }),
    post: (url, options = {}) =>
      request.post(url, { headers: { ...headers, ...options.headers }, ...options }),
    put: (url, options = {}) =>
      request.put(url, { headers: { ...headers, ...options.headers }, ...options }),
    delete: (url, options = {}) =>
      request.delete(url, { headers: { ...headers, ...options.headers }, ...options }),
  };
}

module.exports = { createApiClient };
