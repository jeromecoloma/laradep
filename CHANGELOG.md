# Changelog

All notable changes to laradep are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.18] - 2026-06-02

### Fixed
- `upload --current-release` now distinguishes an SSH connection failure (timeout, refused, auth) from a genuinely missing release. On a non-zero ssh exit it reports a connection error instead of the misleading "No current active release found on the server."

## [1.0.17] - 2026-05-23

### Added
- SSH keepalive (`ServerAliveInterval=30`, `ServerAliveCountMax=10`) on every ssh/rsync call to prevent long-running deploys from dropping with exit 255.
- Remote deploy block now runs under `set -Eeuo pipefail` with an `ERR` trap that reports the failing line number and exit code.
- SSH heredoc output is tee'd to `<log>-ssh.log`, and on failure the last 40 lines are dumped to the terminal so the real error is always visible.

### Fixed
- Broadened the rsync itemize-code regex to include `t/s/p/o/g/u/a/x/n/?` so attribute-only changes (`.d..t....`, `<f..t....`) parse instead of falling through.
- Switched pretty-print lines from `echo -e` to `printf` so file paths containing backslash escapes can't mangle output.
- Defensive split: if two rsync itemize lines get glued into a single `read` chunk, strip the trailing entry instead of printing it as part of the previous path.

## [1.0.16] - 2026-05-22

### Fixed
- Dropped `--progress` from the rsync flags (`-Ppavlzi` → `--partial -pavlzi`) so dry-run and live upload output is no longer jumbled by carriage-return progress fragments getting glued onto the pretty-printed itemized lines.

## [1.0.15] - 2026-05-04

### Changed
- Aligned SSH/rsync wiring with the canonical implementation: `SSH_OPTS` is now a proper bash array (not a string), `RSYNC_SSH_TARGET` replaces `RSYNC_REMOTE`, and `--rsh` quoting uses `printf '%q'` so values with spaces survive correctly. Fixes JUMP-proxy / ProxyJump usage that was broken by 1.0.14's string-based form.
- Added support for `RSYNC_SSH_PROXY_JUMP`, `RSYNC_SSH_PROXY_COMMAND`, `RSYNC_SSH_CONFIG_FILE`, and `RSYNC_SSH_EXTRA_OPTS` (auto-applied to every ssh and rsync call).
- `upload` summary now branches on alias vs. user/host, and reports proxy/config/extra-opts when set.
- `connect` reports the alias name when `RSYNC_SSH_HOST_ALIAS` drives the connection.
- Help text documents all SSH config variables.

## [1.0.14] - 2026-05-04

### Added
- `RSYNC_SSH_HOST_ALIAS` config variable: when set, all ssh/rsync invocations target the alias verbatim and `~/.ssh/config` (User, HostName, Port, IdentityFile, ProxyJump, …) drives the connection. Works through jump hosts.
- `load_config` now fails fast with a clear message when neither `RSYNC_USER`+`RSYNC_HOST` nor `RSYNC_SSH_HOST_ALIAS` is defined (previously the script proceeded with an empty `@:22` target).

### Changed
- All ssh/rsync call sites now build their target through `RSYNC_REMOTE` / `RSYNC_SSH_OPTS` / `RSYNC_RSH_OPTS` helpers set in `load_config`, eliminating the duplicated `-p $PORT -i $KEY user@host` form.

## [1.0.13] - 2026-05-04

### Added
- `seed` command: rsyncs local `www/storage/` (and optional `www/database/database.sqlite`) into the remote `shared/` tree so initial files survive the release symlink swap. Dry-run by default; `--live` applies; `--force` overwrites an existing remote SQLite.
- Zsh completion entries for `seed` (`--live`, `--force`).
- Setup post-run hint pointing at `laradep seed` as an optional pre-deploy step.

## [1.0.12] - prior

- `RSYNC_LARADEP` marker variable in config samples to identify laradep-managed projects.

## [1.0.11] - prior

- `--current-release` option for `upload` to deploy into the active release directory.
- Safer resolution of relative `RSYNC_UPLOAD_SRC` paths.

## [1.0.10] - prior

- Derive `PROJECT_ROOT` from `CONFIG_DIR`; resolve relative `RSYNC_UPLOAD_SRC` against it inside `load_config()`.

## [1.0.8] - prior

- Persistent SQLite database support via `RSYNC_DATABASE_ENABLE` and `shared/database/` symlink.

## [1.0.6] - prior

- Support for legacy `.env` naming formats (`.staging.env` / `.production.env`) alongside `.env.staging` / `.env.production`.

## [1.0.4] - prior

- Default SSH key path (`~/.ssh/id_rsa`) and SSH port handling.
- Git-root config path takes priority over current-directory `_scripts/`.
