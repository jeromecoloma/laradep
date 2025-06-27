# 🚀 Laradep - Laravel Deployment Tool

A comprehensive command-line deployment tool specifically designed for Laravel applications. Streamline your deployment workflow with zero-downtime deployments, automatic cache management, Slack notifications, and more.

## ✨ Features

- **🔄 Zero-downtime deployments** with release management
- **📦 Automatic release versioning** with rollback capabilities
- **🔧 Laravel maintenance mode** management (`artisan down/up`)
- **♻️ Cloudflare cache purging** integration
- **📱 Slack notifications** with customizable messages
- **🗂️ Release cleanup** with interactive deletion
- **🔗 SSH connection** shortcuts
- **⚡ Zsh completion** with smart tab completion
- **🎯 Multi-environment** support (staging/production)

## 🚦 Quick Start

### One-line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/jeromecoloma/laradep/main/install.sh | bash
```

### Manual Installation

1. **Download and install:**
   ```bash
   git clone https://github.com/jeromecoloma/laradep.git
   cd laradep
   chmod +x install.sh
   ./install.sh
   ```

2. **Restart your shell** or run:
   ```bash
   source ~/.zshrc
   ```

## 📖 Usage

### Basic Commands

```bash
# Initial server setup
laradep setup --env=staging

# Deploy to staging (dry-run)
laradep upload --env=staging

# Deploy to production (live)
laradep upload --env=production --live

# Rollback to previous release
laradep rollback --env=production --release=202501270830

# List available releases
laradep releases --env=production

# Maintenance mode
laradep down --env=production --message="Scheduled maintenance"
laradep up --env=production
```

### Advanced Usage

```bash
# Upload with custom Slack notification
laradep upload --env=production --live --custom="🎉 New feature deployed!"

# Remove old releases
laradep remove --env=staging --release=202501260800 --force

# Purge Cloudflare cache
laradep purge --env=production

# Connect to server
laradep connect --env=staging
```

## ⚙️ Configuration

Laradep looks for configuration files in these locations:
- `_scripts/rsync.cfg` (production)
- `_scripts/rsync-staging.cfg` (staging)
- `scripts/rsync*.cfg`
- `.deploy/rsync*.cfg`

### Sample Configuration (`_scripts/rsync.cfg`)

```bash
# Server connection
RSYNC_USER="deploy"
RSYNC_HOST="your-server.com"
RSYNC_PORT="22"
RSYNC_SSH_KEY="$HOME/.ssh/id_rsa"

# Deployment paths
RSYNC_UPLOAD_SRC="./www/"
RSYNC_UPLOAD_DEST="/var/www/your-app"

# Cloudflare integration (optional)
RSYNC_CLOUDFLARE_ENABLE="true"
RSYNC_CLOUDFLARE_ZONE_ID="your-zone-id"
RSYNC_CLOUDFLARE_HOST="your-domain.com"

# Post-deployment script (optional)
RSYNC_AFTER_SCRIPT="php artisan migrate --force && php artisan config:cache"
```

### Slack Configuration

**`~/bin/slackbootstrap` or `~/.slackbootstrap`:**
```bash
# Slack webhook URL
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Default settings
SLACK_CHANNEL="deployments"
SLACK_USERNAME="Laradep Bot"
SLACK_EMOJI="rocket"
SLACK_UPLOAD_MESSAGE="🚀 Deployment completed successfully to {env} environment"
```

**`~/.slackrc` (alternative config file):**
```bash
# Clean, modern variable names
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
SLACK_CHANNEL="deployments"
SLACK_USERNAME="Laradep Bot"
```

### Cloudflare Configuration

**`~/.cloudflarerc`:**
```bash
# Cloudflare API Token (recommended - more secure)
CLOUDFLARE_API_TOKEN="your-cloudflare-api-token-here"

# Alternative: Global API Key (less secure, not recommended)
# CLOUDFLARE_EMAIL="your-email@domain.com"
# CLOUDFLARE_API_KEY="your-global-api-key"
```

## 🎯 Tab Completion

Laradep includes intelligent Zsh completion that provides:

- **Command completion**: `laradep up<TAB>` → `upload`
- **Flag completion**: `laradep upload --<TAB>` → shows all available flags
- **Environment completion**: `laradep upload --env=<TAB>` → `staging`, `production`
- **Live release completion**: `laradep rollback --release=<TAB>` → fetches actual releases from server
- **Context-aware options**: Different commands show relevant flags

## 📂 Project Structure

Your Laravel project should follow this structure:

```
your-laravel-app/
├── _scripts/                 # Deployment configs
│   ├── rsync.cfg            # Production config
│   ├── rsync-staging.cfg    # Staging config
│   └── exclude-upload.sync  # Files to exclude
├── www/                     # Laravel application
│   ├── app/
│   ├── public/
│   └── artisan
└── ...
```

## 🔧 Commands Reference

| Command | Description | Key Options |
|---------|-------------|-------------|
| `setup` | Initialize server environment | `--env` |
| `upload` | Deploy Laravel application | `--env`, `--live`, `--release` |
| `rollback` | Switch to previous release | `--env`, `--release` |
| `releases` | List available releases | `--env` |
| `remove` | Delete old releases | `--env`, `--release`, `--force` |
| `down` | Enable maintenance mode | `--env`, `--message` |
| `up` | Disable maintenance mode | `--env`, `--message` |
| `purge` | Clear Cloudflare cache | `--env` |
| `notify` | Send Slack notification | `--env`, `--message`, `--custom` |
| `connect` | SSH to server | `--env` |

## 🔒 Security Best Practices

1. **Use SSH keys** for authentication (not passwords)
2. **Restrict SSH access** to deployment user
3. **Set proper file permissions** (755 for directories, 644 for files)
4. **Use environment-specific configurations**
5. **Limit Cloudflare API token** permissions
6. **Keep Slack webhooks** private

## 🛠️ Development

### Local Development Setup

```bash
git clone https://github.com/jeromecoloma/laradep.git
cd laradep
```

### File Structure

```
laradep/
├── laradep              # Main script
├── completions/         # Zsh completion
│   └── _laradep
├── install.sh           # Installation script
├── README.md           # This file
└── examples/           # Configuration examples
    ├── rsync.cfg.example
    └── exclude-upload.sync.example
```

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 Examples

### Complete Deployment Workflow

```bash
# 1. Initial setup (one-time)
laradep setup --env=production

# 2. Deploy new release
laradep upload --env=production --live

# 3. If issues arise, rollback
laradep rollback --env=production --release=202501270800

# 4. Clean up old releases
laradep remove --env=production
```

### Maintenance Window

```bash
# Start maintenance
laradep down --env=production --message="Deploying v2.0 - Back online in 10 minutes"

# Deploy updates
laradep upload --env=production --live

# End maintenance
laradep up --env=production --message="v2.0 is now live!"
```

## 🆘 Troubleshooting

### Common Issues

**Command not found:**
```bash
# Check if ~/bin is in PATH
echo $PATH

# Add to ~/.zshrc if missing
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Permission denied:**
```bash
# Make script executable
chmod +x ~/bin/laradep
```

**Tab completion not working:**
```bash
# Rebuild completion cache
rm ~/.zcompdump*
exec zsh
```

**Config file not found:**
```bash
# Check current directory for _scripts/
ls -la _scripts/

# Verify config file exists
cat _scripts/rsync.cfg
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Credits

Built with ❤️ for the Laravel community.

---

**Found this useful?** ⭐ Star the repo and share with your team!
