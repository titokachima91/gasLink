const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizePhone,
  isValidTzPhone,
  brandColor,
} = require('./firebase-bridge');

test('normalizes every Tanzanian phone format used by the app', () => {
  for (const raw of [
    '0767304776',
    '767304776',
    '255767304776',
    '+255767304776',
    '+255 767 304 776',
  ]) {
    assert.equal(normalizePhone(raw), '+255767304776');
    assert.equal(isValidTzPhone(normalizePhone(raw)), true);
  }
});

test('rejects malformed phones', () => {
  assert.equal(isValidTzPhone(normalizePhone('12345')), false);
  assert.equal(isValidTzPhone(normalizePhone('')), false);
});

test('maps brand colours and Swahili aliases', () => {
  assert.deepEqual(brandColor('Oryx Gas'), {
    color: 'Red',
    aliases: ['red', 'nyekundu'],
  });
  assert.equal(brandColor('Manjis Gas').color, 'Yellow');
  assert.equal(brandColor('Mihan Gas').color, 'Yellow');
  assert.equal(brandColor('Taifa Gas').color, 'Blue');
  assert.equal(brandColor('O-Lake Gas').color, 'Green');
  assert.equal(brandColor('Unknown Gas').color, null);
});
