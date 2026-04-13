# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Laradep is a comprehensive command-line deployment tool specifically designed for Laravel applications. It's a Bash-based CLI tool that provides zero-downtime deployments, release management, rollback capabilities, Slack notifications, and Cloudflare cache purging.

## Architecture

### Core Components

**Main Script (`laradep`)**: Single 1685-line Bash script containing all deployment logic. The architecture follows a command-pattern with dedicated functions for each operation:

- Configuration detection and loading (`detect_config_directory`, `load_config`)
- Command handlers (prefixed with `cmd_`) for each major operation
- Slack notification system with predefined messages and emoji mapping
- Release-based deployment system using timestamped directories and symlinks

**Installation System (`install.sh`)**: Self-contained installer that:
- Downloads latest version from GitHub
- Installs to `~/bin/laradep`
- Sets up Zsh completions in `~/.zsh/completions/_laradep`
- Configures PATH and fpath in `~/.zshrc`

**Zsh Completion (`completions/_laradep`)**: Provides intelligent tab completion including dynamic release fetching from remote servers.

### Release Management System

The deployment system uses a directory structure on the remote server:

```
/var/www/your-app/
├── releases/
│   ├── 202501270830/     # Timestamped releases
│   ├── 202501270900/
│   └── 202501271000/
├── shared/
│   └── storage/          # Persistent storage symlinked to releases
│       └── framework/
│           ├── cache/
│           ├── sessions/
│           └── views/
└── current -> releases/202501271000/  # Symlink to active release
```

**Key deployment flow** (laradep:1298-1498):
1. Rsync files to timestamped release directory
2. Create shared storage symlinks
3. Initialize git repository in release for tracking
4. Symlink current -> new release (atomic cutover)
5. Run post-deployment scripts (migrations, cache clearing)
6. Auto-purge Cloudflare cache
7. Send Slack notification

### Configuration Detection

Config files are searched in priority order (laradep:35-66):
1. Git root `_scripts/` directory (if in git repo)
2. Current directory `_scripts/`
3. Current directory `scripts/`
4. Current directory `.deploy/`
5. Home directory `~/.deploy/`

After detection, `PROJECT_ROOT` is derived by stripping the config subdirectory suffix (`_scripts`, `scripts`, or `.deploy`) from `CONFIG_DIR`. This ensures relative paths like `RSYNC_UPLOAD_SRC="./www/"` resolve correctly even when laradep is run from a subdirectory (e.g., `www/`).

Environment-specific configs:
- Production: `rsync.cfg`
- Staging: `rsync-staging.cfg`

### Slack Integration

Supports both modern and legacy config formats (laradep:627-776):
- Primary config: `~/.slackbootstrap` or `~/bin/slackbootstrap`
- Secondary config: `~/.slackrc` or `~/.iwslackrc`
- Legacy support: `~/bin/iwdevbootstrap` and `~/.iwslackrc`

Variables with SLACK_ prefix take precedence over IWDEV_ legacy variables.

### Environment File Handling

Supports two .env naming conventions (laradep:1449-1459):
1. New format: `.env.staging` or `.env.production`
2. Legacy format: `.staging.env` or `.production.env`

Script checks for new format first, then falls back to legacy.

### SQLite Database Handling

Laradep includes optional SQLite database management to prevent overwriting production data during deployments (laradep:1465-1477).

**Configuration:**
- Enable via `RSYNC_DATABASE_ENABLE="true"` in rsync.cfg
- Requires database files to be excluded in exclude-upload.sync

**Architecture:**
1. Setup creates `shared/database/` directory (laradep:600)
2. During deployment, uploaded .sqlite files are deleted from release
3. Creates symlink: `www/database/database.sqlite` → `shared/database/database.sqlite`
4. First deployment creates empty database.sqlite in shared storage if it doesn't exist

**Implementation pattern:**
- Checks if database directory exists in release
- Removes any uploaded database files to prevent overwriting
- Creates persistent symlink to shared storage
- Falls through silently if feature is disabled

## Development Commands

### Testing Changes

```bash
# Test script syntax
bash -n laradep

# Test in dry-run mode
./laradep upload --env=staging

# Test with actual deployment
./laradep upload --env=staging --live
```

### Version Management

Update version in three places:
1. `laradep` line 7: `LARADEP_VERSION="1.0.6"`
2. GitHub release tag
3. Commit message should reference version

### Installation Testing

```bash
# Test local installation
./install.sh

# Test remote installation
curl -fsSL https://raw.githubusercontent.com/jeromecoloma/laradep/main/install.sh | bash

# Force reinstall
./install.sh --force
```

## Key Implementation Details

### SSH Connection Pattern

All SSH commands use consistent format (laradep:594):
```bash
ssh -p "$RSYNC_PORT" -i "$RSYNC_SSH_KEY" "$RSYNC_USER@$RSYNC_HOST" bash -s <<EOF
  # remote commands here
EOF
```

### Release Validation

When rolling back or removing releases, always:
1. Fetch current release symlink target
2. Verify target release exists
3. Prevent deletion/modification of current release
4. Provide clear error messages with suggested actions

### Cloudflare API Integration

Uses Bearer token authentication (laradep:964-1024):
- Config file: `~/.cloudflarerc` or `~/.iwcloudflarerc`
- Requires: `CLOUDFLARE_API_TOKEN`
- Legacy support: `CLOUDFLARE_EMAIL` + `CLOUDFLARE_API_KEY`

### Error Handling Pattern

Commands use status codes embedded in SSH output:
```bash
echo "STATUS:SUCCESS" or "STATUS:FAILED" or "STATUS:NO_ARTISAN"
```
These are parsed after command execution to determine next steps.

## Configuration Files

### Required Files in Laravel Project

```
your-laravel-app/
├── _scripts/                          # Deployment configs directory
│   ├── rsync.cfg                     # Production config
│   ├── rsync-staging.cfg             # Staging config
│   ├── exclude-upload.sync           # Production exclusions
│   └── exclude-upload-staging.sync   # Staging exclusions
└── www/                              # Laravel application root
    ├── .env.production               # Environment file (or .production.env)
    ├── .env.staging                  # Environment file (or .staging.env)
    └── artisan
```

### Config Variables Reference

**Required in rsync.cfg:**
- `RSYNC_LARADEP`: Marker to identify laradep-managed projects (always `"true"`)
- `RSYNC_USER`: SSH username
- `RSYNC_HOST`: Server hostname
- `RSYNC_UPLOAD_SRC`: Local source path (e.g., `./www/`). Relative paths are resolved against `PROJECT_ROOT`
- `RSYNC_UPLOAD_DEST`: Remote destination path (e.g., `/var/www/app`)

**Optional:**
- `RSYNC_PORT`: SSH port (default: 22)
- `RSYNC_SSH_KEY`: SSH key path (default: `~/.ssh/id_rsa`)
- `RSYNC_CLOUDFLARE_ENABLE`: Enable cache purging (`true`/`false`)
- `RSYNC_CLOUDFLARE_ZONE_ID`: Cloudflare zone ID
- `RSYNC_CLOUDFLARE_HOST`: Domain to purge
- `RSYNC_DATABASE_ENABLE`: Enable SQLite database symlink handling (`true`/`false`)
- `RSYNC_AFTER_SCRIPT`: Commands to run after deployment

## Common Patterns

### Adding New Commands

1. Add command to `VALID_COMMANDS` array (line 1538)
2. Create `cmd_function_name()` following existing patterns
3. Map command name to function in case statement (lines 1545-1564)
4. Add command routing in main case statement (lines 1638-1684)
5. Update help text in `show_help()` and `show_usage()`
6. Add Zsh completion support in `completions/_laradep`

### Adding Slack Message Types

1. Add case in `get_predefined_message()` (lines 440-475)
2. Add emoji mapping in `get_predefined_emoji()` (lines 477-521)
3. Document in `show_slack_usage()` (lines 357-394)

### Color Output Convention

Use consistent color variables throughout:
- `C1` (Cyan): Info/progress markers (→)
- `C2` (Green): Success messages
- `C3` (Yellow): Warnings
- `C4` (Red): Errors
- `C5` (Magenta): Special highlights
- `CE`: Reset

## Important Constraints

1. **Backward compatibility**: Support both old and new naming conventions for .env files and config variables
2. **Safety checks**: Always verify releases exist before operations, protect current release from deletion
3. **Dry-run default**: Upload command defaults to dry-run unless `--live` flag is explicit
4. **SSH key paths**: Default to `~/.ssh/id_rsa` if not specified
5. **Port handling**: Support both `RSYNC_PORT` and `RSYNC_SSH_PORT` variables
6. **Setup protection**: Require exact "YES" confirmation for setup command

## Code Style

- Use descriptive function names prefixed with `cmd_` for command handlers
- Always validate environment parameter before loading config
- Include informative error messages with suggested solutions (ℹ️ prefix)
- Use emoji consistently for visual feedback
- Keep related functionality grouped together with section comments
- Follow existing SSH command patterns for consistency
