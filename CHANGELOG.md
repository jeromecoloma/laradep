# Changelog

All notable changes to laradep are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
