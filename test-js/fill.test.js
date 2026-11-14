// Tests the script the app injects into the booking page. node --test test-js/*.test.js
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('jsdom');

const script = fs.readFileSync(path.join(__dirname, '..', 'assets', 'fill.js'), 'utf8');

function page() {
  const html = fs.readFileSync(path.join(__dirname, 'fixtures', 'devotees.html'), 'utf8');
  const dom = new JSDOM(html, { runScripts: 'outside-only' });
  dom.window.eval(script);
  return dom.window;
}

const group = [
  { name: 'Venkata Reddy', age: '58', gender: 'Male', idType: 'Aadhaar', idNumber: '234567890123' },
  { name: 'Lakshmi Devi', age: '54', gender: 'Female', idType: 'Passport', idNumber: 'K1234567' },
];

const all = (w, sel) => Array.from(w.document.querySelectorAll(sel)).map((e) => e.value);

test('fills each devotee row in order', () => {
  const w = page();
  const n = w.TtdHelper.fillRows(group);
  assert.equal(n, 10);
  assert.deepEqual(all(w, '[formcontrolname=devoteeName]'), ['Venkata Reddy', 'Lakshmi Devi']);
  assert.deepEqual(all(w, '[formcontrolname=age]'), ['58', '54']);
  assert.deepEqual(all(w, '[formcontrolname=gender]'), ['M', 'F']);
  assert.deepEqual(all(w, '[formcontrolname=proofType]'), ['AADHAR', 'PASSPORT']);
  assert.deepEqual(all(w, '[formcontrolname=proofNumber]'), ['234567890123', 'K1234567']);
});

test('leaves mobile, captcha and look-alike labels alone', () => {
  const w = page();
  w.TtdHelper.fillRows(group);
  assert.equal(w.document.getElementById('mobile').value, '');
  assert.equal(w.document.getElementById('cap').value, '');
  assert.equal(w.document.getElementById('hint').value, '', '"valid number" is not an ID number');
});

test('does not overwrite rows the user already typed', () => {
  const w = page();
  w.document.querySelector('[formcontrolname=devoteeName]').value = 'Typed by hand';
  w.TtdHelper.fillRows(group);
  assert.equal(w.document.querySelector('[formcontrolname=devoteeName]').value, 'Typed by hand');
});

test('chip insert types into the box last tapped', () => {
  const w = page();
  assert.equal(w.TtdHelper.insert('x'), 'Tap a box on the page first.');
  const age = w.document.querySelectorAll('[formcontrolname=age]')[1];
  age.focus();
  age.dispatchEvent(new w.FocusEvent('focusin', { bubbles: true }));
  assert.equal(w.TtdHelper.insert('54'), 'ok');
  assert.equal(age.value, '54');
});

test('chip insert picks the matching option in a list', () => {
  const w = page();
  const sel = w.document.querySelectorAll('[formcontrolname=proofType]')[0];
  sel.dispatchEvent(new w.FocusEvent('focusin', { bubbles: true }));
  assert.equal(w.TtdHelper.insert('Voter ID'), 'ok');
  assert.equal(sel.value, 'VOTER');
  assert.equal(w.TtdHelper.insert('Ration card'), 'No matching choice in this list.');
});

test('chip insert refuses the captcha box', () => {
  const w = page();
  const cap = w.document.getElementById('cap');
  cap.dispatchEvent(new w.FocusEvent('focusin', { bubbles: true }));
  assert.equal(w.TtdHelper.insert('1234'), 'This box is for you to type yourself.');
  assert.equal(cap.value, '');
});
