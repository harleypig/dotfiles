---
paths:
  - "**/nginx.conf"
  - "**/nginx/**/*.conf"
  - "**/conf.d/*.conf"
  - "**/sites-available/**"
  - "**/sites-enabled/**"
  - "**/*.nginx"
---

# nginx Rules

**Version:** v1.0.0

Conventions for authoring nginx configuration — reverse proxy, TLS
termination, security headers, and static/SPA serving. This rule is the
*authoring* side; **runtime verification that the headers are actually
present is DAST's job** (`rules/zap.md` / the qa Security dimension), so the
two are complementary — author here, verify there.

## Detection

Active when the repo contains an nginx config — an `nginx.conf`, a `server {}`
/ `http {}` block, or files under `conf.d/` / `sites-available/`. Dormant for
non-nginx `.conf` files (the path globs are a coarse gate).

## Reverse proxy

Forward the client's real context to the upstream; a proxy that hides it
breaks logging, rate limiting, and the app's own scheme detection.

```nginx
location /api/ {
    proxy_pass http://backend:8000;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;   # https when TLS terminates here
}
```

- Set **`X-Forwarded-Proto`** when nginx terminates TLS in front of a
  plain-HTTP backend — the app needs it to know the external scheme (OAuth
  redirects, secure-cookie decisions).
- The app must **trust these headers only from a known proxy** (set
  `X-Forwarded-For` from `$proxy_add_x_forwarded_for`, not blindly), and the
  backend should read the forwarded scheme/ip, not the direct connection.

## TLS termination

```nginx
ssl_protocols       TLSv1.2 TLSv1.3;   # no TLS 1.0/1.1
ssl_ciphers         HIGH:!aNULL:!MD5;  # or a curated modern suite
ssl_prefer_server_ciphers off;         # client picks (matters for TLS 1.3)
ssl_session_cache   shared:SSL:10m;
ssl_stapling on; ssl_stapling_verify on;   # OCSP stapling (public certs)
```

- **TLS 1.2 + 1.3 only.** Enable **HTTP/2** (`http2 on;`).
- Generate dev certs with a local CA (e.g. mkcert) and mount them read-only;
  never commit private keys (a `detect-private-key` hook should guard this).
- Add **HSTS** for production HTTPS (omit on a `127.0.0.1` dev cert):

  ```nginx
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  ```

## Security headers

Author the standard set at the `server` level. Two non-obvious footguns:

- **`always`** — without it, nginx omits the header on **error responses**
  (4xx/5xx), so a misconfigured app or an error page ships *unprotected*.
  Always use `always` on security headers.
- **`add_header` inheritance** — `add_header` directives are inherited from a
  parent block **only if the child defines none of its own**. A `location`
  that adds even one header **drops all server-level headers** for that
  location. Re-declare (or use an `include` snippet) wherever you add a
  location-level header.

```nginx
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy        "no-referrer" always;
add_header Content-Security-Policy "default-src 'self'; ..." always;
# Frame protection: prefer CSP frame-ancestors; X-Frame-Options for old UAs.
add_header X-Frame-Options "DENY" always;
```

- **CSP is the main control** — size it to exactly the origins the app loads
  (scripts, connect/ws, images, fonts, frames). Keep `frame-ancestors`,
  `object-src 'none'`, `base-uri 'self'`. Avoid `'unsafe-inline'`; when a
  dependency forces it, record the exception (and any DAST allowlist) so it's
  a decision, not drift.
- **`Permissions-Policy`** — to let a feature work inside a **cross-origin
  iframe** (e.g. a third-party SDK needing `encrypted-media`/`autoplay`), you
  must **delegate** it, not allow it for `self` only: the default `self`
  blocks the delegation and the embedded frame silently fails. Scope the
  delegation as tightly as the embedding allows (CSP `frame-src` already
  bounds which origins can be framed).

## Static / SPA serving

```nginx
root /usr/share/nginx/html;
index index.html;
location / {
    try_files $uri $uri/ /index.html;   # SPA fallback to the app shell
}
```

## Hardening

- `server_tokens off;` — don't leak the nginx version.
- Rate-limit sensitive endpoints with `limit_req` (define a
  `limit_req_zone`, apply per-location).
- Set a sane `client_max_body_size`; enable `gzip` for text assets.
- Deny dotfiles: `location ~ /\. { deny all; }`.

## Agent Behavior

- When editing an nginx config, preserve the reverse-proxy header set and the
  `always` flag on every security header; never drop server-level headers by
  adding a bare location-level `add_header`.
- Size CSP / `Permissions-Policy` to what the app actually needs; record any
  `'unsafe-inline'` or delegation exception.
- After header/CSP changes, **verify at runtime via DAST** (`rules/zap.md`) —
  this rule authors the headers; the scan proves they're served (including on
  error responses) and reconciles any allowlist.
