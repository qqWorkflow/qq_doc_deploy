# qq Documentation Server

Automatic documentation deployment from Git repository using Docker.

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/qqWorkflow/qq_doc_deploy.git
cd qq_doc_deploy
```

### 2. Configuration

```bash
cp .env.example .env
```

### 3. Create SSH Deploy Key

```bash
mkdir -p .ssh
ssh-keygen -t ed25519 -f .ssh/deploy_key -N "" -C "qq_doc deploy key"
```

### 4. Add Key to GitHub

```bash
cat .ssh/deploy_key.pub
```

1. Go to GitHub repo → **Settings** → **Deploy keys**
2. Click **Add deploy key**
3. Paste the public key
4. **DO NOT** check "Allow write access" (read-only)

### 5. Start

```bash
docker-compose up -d
```

## Configuration

All settings in `.env` file:

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_REPO` | `git@github.com:Tybeos/qq_doc.git` | Git repository (SSH format) |
| `SSH_KEY_PATH` | `./.ssh/deploy_key` | Path to SSH key |
| `GIT_BRANCH` | `main` | Git branch |
| `SYNC_PERIOD` | `60s` | Sync interval |
| `HTTP_PORT` | `80` | HTTP port for nginx |
| `HTTPS_PORT` | `443` | HTTPS port for nginx (optional) |

## HTTPS Setup (Optional)

For local HTTPS with trusted certificates using `mkcert`:

### 1. Install mkcert

**Windows:**
```bash
choco install mkcert
# or
winget install FiloSottile.mkcert
```

**Linux:**
```bash
sudo apt install mkcert
```

**macOS:**
```bash
brew install mkcert
```

### 2. Setup Local CA (one-time)

```bash
mkcert -install
```

### 3. Generate Certificates

```bash
mkdir -p certs
mkcert -key-file certs/server.key -cert-file certs/server.crt localhost 127.0.0.1 ::1
```

### 4. Enable HTTPS

Uncomment in `.env`:
```bash
HTTPS_PORT=443
```

### 5. Restart

```bash
docker-compose down && docker-compose up -d
```

Now accessible at `https://localhost`
