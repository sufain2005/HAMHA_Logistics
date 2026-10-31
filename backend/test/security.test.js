const { test } = require('node:test');
const assert = require('node:assert/strict');
process.env.JWT_SECRET = 'test-only-secret-with-more-than-32-characters';
let rows = [];
let calls = [];
require.cache[require.resolve('../src/config/db')] = {
  exports: { query: async (sql, params) => { calls.push({ sql, params }); return { rows }; } },
};
const auth = require('../src/controllers/auth.controller');
const drivers = require('../src/controllers/driver.controller');
const bcrypt = require('bcryptjs');
const response = () => ({ code: 200, status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } });
const fail = error => { throw error; };

test('login rejects missing passwords before querying the database', async () => {
  calls = [];
  const res = response();
  await auth.login({ body: { email: 'owner@example.com' } }, res, fail);
  assert.equal(res.code, 400);
  assert.equal(calls.length, 0);
});
test('former override passwords cannot authenticate another user', async () => {
  for (const password of ['Admin@123456', 'Driver@123456']) {
    rows = [{ id: 'owner', role: 'admin', password_hash: await bcrypt.hash('actual-private-password', 4) }];
    const res = response();
    await auth.login({ body: { email: 'owner@example.com', password } }, res, fail);
    assert.equal(res.code, 401);
    assert.equal(res.body.token, undefined);
  }
});
test('correct password still authenticates', async () => {
  rows = [{ id: 'owner', role: 'admin', password_hash: await bcrypt.hash('actual-private-password', 4) }];
  const res = response();
  await auth.login({ body: { email: 'owner@example.com', password: 'actual-private-password' } }, res, fail);
  assert.equal(res.code, 200);
  assert.ok(res.body.token);
  assert.equal(res.body.user.password_hash, undefined);
});
test('static OTP cannot verify a phone', async () => {
  calls = [];
  const res = response();
  await auth.verifyOtp({ body: { phone: '123', otpCode: '889900' } }, res, fail);
  assert.equal(res.code, 503);
  assert.equal(calls.length, 0);
});
test('order status update binds the authenticated driver and previous state', async () => {
  calls = []; rows = [];
  const res = response();
  await drivers.updateOrderStatus({ user: { id: 'driver-one' }, params: { orderId: 'another-order' }, body: { status: 'delivered' } }, res, fail);
  assert.equal(res.code, 404);
  assert.deepEqual(calls[0].params, ['delivered', 'another-order', 'driver-one']);
  assert.match(calls[0].sql, /driver_id = \$3/);
  assert.match(calls[0].sql, /status = 'in_transit'/);
});
