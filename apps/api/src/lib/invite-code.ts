import { randomBytes } from 'node:crypto';

// Crockford-style alphabet — confusable harfler (I, L, O, U) çıkarıldı.
const ALPHABET = 'ABCDEFGHJKMNPQRSTVWXYZ23456789';

export function generateInviteCode(length = 8): string {
  const bytes = randomBytes(length);
  let out = '';
  for (let i = 0; i < length; i += 1) {
    out += ALPHABET[bytes[i]! % ALPHABET.length];
  }
  return out;
}
