/* Injected into the booking page. Two things only:
   1. remember which box you last tapped, so a chip can type into it;
   2. on request, fill devotee rows by their labels (best effort, you check it).
   Never clicks buttons, never touches login, OTP, captcha or payment boxes. */
(function () {
  if (window.TtdHelper) return;

  var last = null;
  document.addEventListener('focusin', function (e) {
    var t = e.target;
    if (t && /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName)) last = t;
  }, true);

  var BLOCK = /captcha|otp|password|passcode|\bpin\b|cvv|card number|expiry|upi id|vpa/i;

  function clean(s) { return (s || '').replace(/\s+/g, ' ').trim(); }

  function labelOf(el) {
    var parts = [];
    if (el.id) {
      var l = document.querySelector('label[for="' + el.id.replace(/"/g, '\\"') + '"]');
      if (l) parts.push(l.textContent);
    }
    var wrap = el.closest('label, mat-form-field, .mat-form-field, .form-group, .ant-form-item, td');
    if (wrap) {
      var lab = wrap.querySelector('label, mat-label, .ant-form-item-label');
      if (lab) parts.push(lab.textContent);
    }
    parts.push(el.getAttribute('aria-label'), el.getAttribute('placeholder'), el.getAttribute('formcontrolname'), el.getAttribute('name'), el.id);
    var row = el.closest('td');
    if (row && row.previousElementSibling) parts.push(row.previousElementSibling.textContent);
    return clean(parts.filter(Boolean).join(' ')).toLowerCase();
  }

  function fire(el, type) { el.dispatchEvent(new Event(type, { bubbles: true })); }

  function setValue(el, value) {
    if (el.tagName === 'SELECT') {
      var want = String(value).toLowerCase();
      var opts = Array.prototype.slice.call(el.options);
      var hit = opts.find(function (o) { return clean(o.textContent).toLowerCase() === want; }) ||
        opts.find(function (o) { return clean(o.textContent).toLowerCase().indexOf(want) === 0; }) ||
        opts.find(function (o) { return o.value.toLowerCase() === want; });
      if (!hit) return false;
      el.value = hit.value;
    } else {
      var proto = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
      var desc = Object.getOwnPropertyDescriptor(proto, 'value');
      if (desc && desc.set) desc.set.call(el, value); else el.value = value;
    }
    fire(el, 'input');
    fire(el, 'change');
    fire(el, 'blur');
    el.style.outline = '2px solid #b8860b';
    return true;
  }

  function usable(el) {
    if (el.disabled || el.readOnly || el.type === 'hidden' || el.type === 'password') return false;
    var s = getComputedStyle(el);
    return s.display !== 'none' && s.visibility !== 'hidden';
  }

  /** Types into the box you last tapped. */
  function insert(value) {
    var el = last;
    if (!el || !document.contains(el)) return 'Tap a box on the page first.';
    if (!usable(el)) return 'That box cannot be typed into.';
    if (BLOCK.test(labelOf(el))) return 'This box is for you to type yourself.';
    // Radio buttons: choose the one whose label matches (gender).
    if (el.type === 'radio') {
      var group = document.querySelectorAll('input[type="radio"][name="' + el.name + '"]');
      for (var i = 0; i < group.length; i++) {
        if (labelOf(group[i]).indexOf(String(value).toLowerCase()) >= 0 || (group[i].value || '').toLowerCase() === String(value).toLowerCase()) {
          group[i].click();
          return 'ok';
        }
      }
      return 'No matching choice here.';
    }
    return setValue(el, value) ? 'ok' : 'No matching choice in this list.';
  }

  // Order matters: ID type before ID number ("Photo ID Proof Type" vs "ID Proof Number").
  var FIELDS = {
    idType: /\b(id|proof|document)\s*type\b|\btype of (id|proof)\b|\bphoto id proof\b(?!.*\b(no|number)\b)/,
    idNumber: /\b(id|proof|card|aadhaa?r)\s*(no|number|#)|\baadhaa?r\b|\bdocument number\b/,
    age: /\bage\b/,
    gender: /gender|\bsex\b/,
    name: /name/,
  };

  function kindOf(el) {
    var l = labelOf(el);
    if (!l || BLOCK.test(l)) return null;
    if (/user ?name|login|email|mobile|phone|city|state|country|address/.test(l)) return null;
    for (var k in FIELDS) if (FIELDS[k].test(l)) return k;
    return null;
  }

  /** Fills the n-th box of each kind with the n-th devotee. Returns how many boxes it filled. */
  function fillRows(devotees) {
    var buckets = { name: [], age: [], gender: [], idType: [], idNumber: [] };
    var els = document.querySelectorAll('input, select, textarea');
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.type === 'radio' || el.type === 'checkbox' || !usable(el)) continue;
      var k = kindOf(el);
      if (k) buckets[k].push(el);
    }
    var count = 0;
    for (var key in buckets) {
      buckets[key].forEach(function (el, idx) {
        var d = devotees[idx];
        if (!d || el.value) return;
        if (setValue(el, d[key])) count++;
      });
    }
    return count;
  }

  window.TtdHelper = { insert: insert, fillRows: fillRows, _kindOf: kindOf };
})();
