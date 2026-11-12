import { Context } from 'hono';

export interface AuthClaims {
  sub: string;
  role: string;
  iat: number;
  exp: number;
}

const enc = new TextEncoder();
const dec = new TextDecoder();

function toBase64Url(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function fromBase64Url(input: string): Uint8Array | null {
  try {
    const padded = input.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((input.length + 3) % 4);
    const bin = atob(padded);
    const out = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) {
      out[i] = bin.charCodeAt(i);
    }
    return out;
  } catch {
    return null;
  }
}

function getSigningSecret(env: { AUTH_JWT_SECRET?: string; ADMIN_API_KEY?: string; GAGE_ENV?: string }): string | null {
  const configured = (env.AUTH_JWT_SECRET || env.ADMIN_API_KEY || '').trim();
  if (configured.length > 0) return configured;
  if ((env.GAGE_ENV || 'production').toLowerCase() !== 'production') {
    return 'gage-local-dev-signing-secret';
  }
  return null;
}

async function importHmacKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify']
  );
}

/** Signs an HMAC-SHA256 stateless token carrying user ID, role, and expiry. */
export async function signAuthToken(
  env: { AUTH_JWT_SECRET?: string; ADMIN_API_KEY?: string; GAGE_ENV?: string },
  claims: Omit<AuthClaims, 'iat' | 'exp'>,
  ttlSeconds = 60 * 60 * 24 * 30
): Promise<string> {
  const secret = getSigningSecret(env);
  if (!secret) {
    throw new Error('AUTH_JWT_SECRET or ADMIN_API_KEY secret is not configured');
  }
  const now = Math.floor(Date.now() / 1000);
  const fullClaims: AuthClaims = {
    sub: claims.sub,
    role: claims.role,
    iat: now,
    exp: now + ttlSeconds,
  };
  const headerB64 = toBase64Url(enc.encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' })));
  const payloadB64 = toBase64Url(enc.encode(JSON.stringify(fullClaims)));
  const unsigned = `${headerB64}.${payloadB64}`;
  const key = await importHmacKey(secret);
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(unsigned));
  return `${unsigned}.${toBase64Url(new Uint8Array(sig))}`;
}

/** Verifies HMAC-SHA256 token signature and expiration; returns claims or null. */
export async function verifyAuthToken(
  env: { AUTH_JWT_SECRET?: string; ADMIN_API_KEY?: string; GAGE_ENV?: string },
  token: string
): Promise<AuthClaims | null> {
  const secret = getSigningSecret(env);
  if (!secret || !token) return null;
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [headerB64, payloadB64, sigB64] = parts;
  const sigBytes = fromBase64Url(sigB64);
  const payloadBytes = fromBase64Url(payloadB64);
  if (!sigBytes || !payloadBytes) return null;

  const key = await importHmacKey(secret);
  const valid = await crypto.subtle.verify(
    'HMAC',
    key,
    sigBytes,
    enc.encode(`${headerB64}.${payloadB64}`)
  );
  if (!valid) return null;

  try {
    const claims = JSON.parse(dec.decode(payloadBytes)) as AuthClaims;
    const now = Math.floor(Date.now() / 1000);
    if (!claims.sub || !claims.exp || claims.exp < now) return null;
    return claims;
  } catch {
    return null;
  }
}

export function isAdminKeyValid(c: Context): boolean {
  const configuredKey = (c.env?.ADMIN_API_KEY || '').trim();
  const providedKey = (c.req.header('X-API-Key') || '').trim();
  if (!configuredKey || !providedKey) return false;
  if (configuredKey.length !== providedKey.length) return false;
  let diff = 0;
  for (let i = 0; i < configuredKey.length; i++) {
    diff |= configuredKey.charCodeAt(i) ^ providedKey.charCodeAt(i);
  }
  return diff === 0;
}

export async function getVerifiedRequestClaims(c: Context): Promise<AuthClaims | null> {
  const auth = c.req.header('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return null;
  const token = auth.slice(7).trim();
  return verifyAuthToken(c.env, token);
}

export async function isAdminOrAuthorizedRole(c: Context, allowedRoles: string[] = ['admin']): Promise<boolean> {
  if (isAdminKeyValid(c)) return true;
  const claims = await getVerifiedRequestClaims(c);
  if (!claims) return false;
  return allowedRoles.includes(claims.role) || claims.role === 'admin';
}

export function isProductionRuntime(c: Context): boolean {
  return (c.env?.GAGE_ENV || 'production').toLowerCase() === 'production';
}
