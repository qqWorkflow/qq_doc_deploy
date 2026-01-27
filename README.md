# QQ Doc Server

Containerized documentation hosting system for QQ Studio. Automatically syncs documentation from GitHub, builds it with Sphinx, and serves it via Nginx.

## Features

- Automatic Git synchronization every 60 seconds
- Instant rebuild on file changes using inotify
- Multi-language support (English and Czech)
- Containerized architecture with Docker Compose
- Health checks for all services

## Architecture

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────┐
│    git-sync     │      │   docs builder   │      │    nginx    │
│  (syncs repo    │ ───> │  (Sphinx build,  │ ───> │   (serves   │
│   every 60s)    │      │  inotify watch)  │      │    HTML)    │
└─────────────────┘      └──────────────────┘      └─────────────┘
```

**Services:**

| Service | Image | Purpose |
|---------|-------|---------|
| git-sync | registry.k8s.io/git-sync/git-sync:v4.4.0 | Pulls documentation repo via SSH |
| docs | Custom (Python 3.12 + Sphinx) | Builds docs, watches for changes |
| nginx | nginx:alpine | Serves static HTML |

## Requirements

- Docker
- Docker Compose

## Quick Start

### 1. Clone this repository

```bash
git clone <this-repo-url>
cd qq_doc
```

### 2. Create configuration

```bash
cp .env.example .env
```

### 3. Set up SSH deploy key

```bash
# Create SSH directory
mkdir -p .ssh

# Generate Ed25519 deploy key
ssh-keygen -t ed25519 -f .ssh/deploy_key -N "" -C "qq_doc deploy key"

# Display public key
cat .ssh/deploy_key.pub
```

### 4. Add deploy key to GitHub

1. Go to your documentation repository on GitHub
2. Navigate to **Settings** > **Deploy keys** > **Add deploy key**
3. Paste the public key from step 3
4. **Do NOT** check "Allow write access" (read-only is sufficient)
5. Click **Add key**

### 5. Configure environment

Edit `.env` file:

```bash
# Git repository URL (SSH format)
GIT_REPO=git@github.com:your-org/your-docs-repo.git

# Path to SSH private key
SSH_KEY_PATH=./.ssh/deploy_key
```

### 6. Start services

```bash
docker-compose up -d
```

### 7. Access documentation

- English: http://localhost/en/
- Czech: http://localhost/cs/

## Documentation Repository Structure

Your documentation repository should have this structure:

```
docs/
├── en/
│   ├── conf.py          # Sphinx configuration
│   ├── index.rst        # or index.md
│   └── ...
└── cs/
    ├── conf.py
    ├── index.rst
    └── ...
```

## Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GIT_REPO` | Documentation repository URL (SSH format) | `git@github.com:org/repo.git` |
| `SSH_KEY_PATH` | Path to SSH private key | `./.ssh/deploy_key` |

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 80 | nginx | HTTP access to documentation |

### Volumes

| Volume | Purpose |
|--------|---------|
| `repo-data` | Shared repository data between git-sync and docs |
| `static-data` | Built HTML files shared between docs and nginx |

## How It Works

### File Change Detection

The system uses **inotify** for instant file change detection:

1. `inotifywait` monitors the docs directory for changes
2. When a `.md`, `.rst`, or `.py` file changes, a rebuild is triggered
3. **Debouncing** (3 seconds) prevents multiple rebuilds when many files change at once
4. Only changed content triggers a rebuild - no CPU usage while idle

### Sync Cycle

1. **git-sync** pulls the repository every 60 seconds
2. When files change, **inotify** detects it immediately
3. After 3 seconds of no changes (debounce), Sphinx rebuilds
4. **nginx** serves the updated HTML

Total update time: ~63 seconds from push to live (60s sync + 3s debounce)

## Commands

### Start services

```bash
docker-compose up -d
```

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f docs
```

### Rebuild docs container

```bash
docker-compose build docs
docker-compose up -d docs
```

### Stop services

```bash
docker-compose down
```

### Check service health

```bash
docker-compose ps
```

### Force documentation rebuild

```bash
docker-compose restart docs
```

## Troubleshooting

### Documentation not updating

1. Check git-sync logs:
   ```bash
   docker-compose logs git-sync
   ```

2. Verify SSH key permissions:
   ```bash
   ls -la .ssh/deploy_key
   # Should be -rw------- (600)
   ```

3. Test SSH connection:
   ```bash
   ssh -i .ssh/deploy_key -T git@github.com
   ```

### Build errors

1. Check docs container logs:
   ```bash
   docker-compose logs docs
   ```

2. Verify Sphinx configuration in your docs repository

### nginx returns 404

1. Check if docs are built:
   ```bash
   docker-compose exec nginx ls /usr/share/nginx/html/en/
   ```

2. Verify nginx configuration:
   ```bash
   docker-compose exec nginx nginx -t
   ```

### Health check failing

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' qq_doc-docs-1

# View health check logs
docker inspect --format='{{json .State.Health}}' qq_doc-docs-1 | jq
```

## Security

- SSH deploy keys provide read-only repository access
- No secrets are stored in the repository
- Container runs with minimal privileges
- nginx serves static files only

## License

MIT
