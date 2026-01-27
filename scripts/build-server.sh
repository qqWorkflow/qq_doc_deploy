#!/bin/bash
# Polls for git commit changes and triggers builds

set -e

SOURCE_DIR="/git/current/docs"
BUILD_DIR="/static"
LOCK_FILE="/tmp/build.lock"
POLL_INTERVAL=60

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

build_docs() {
    (
        flock -n 200 || {
            log_info "Build already in progress, skipping..."
            return 0
        }

        log_info "Building documentation..."

        local build_failed=0

        if [ -d "$SOURCE_DIR/en" ]; then
            log_info "Building English docs..."
            if sphinx-build -b html "$SOURCE_DIR/en" "$BUILD_DIR/en" 2>&1; then
                log_info "English docs built successfully."
            else
                log_info "English docs build failed!"
                build_failed=1
            fi
        fi

        if [ -d "$SOURCE_DIR/cs" ]; then
            log_info "Building Czech docs..."
            if sphinx-build -b html "$SOURCE_DIR/cs" "$BUILD_DIR/cs" 2>&1; then
                log_info "Czech docs built successfully."
            else
                log_info "Czech docs build failed!"
                build_failed=1
            fi
        fi

        if [ $build_failed -eq 0 ]; then
            log_info "Build complete."
            touch /tmp/docs-ready
        else
            log_info "Build completed with errors."
        fi

    ) 200>"$LOCK_FILE"
}

get_commit_hash() {
    # Try multiple methods to get commit hash
    if [ -d "/git/current/.git" ]; then
        git -C /git/current rev-parse HEAD 2>/dev/null || echo ""
    elif [ -f "/git/current/.git" ]; then
        # Worktree - .git is a file pointing to actual git dir
        git -C /git/current rev-parse HEAD 2>/dev/null || echo ""
    else
        # Fallback: use symlink target as "hash"
        readlink /git/current 2>/dev/null || echo ""
    fi
}

# Wait for git-sync to clone repo
log_info "Waiting for repository..."
while [ ! -L "/git/current" ] && [ ! -d "/git/current" ]; do
    sleep 5
    log_info "Still waiting for /git/current..."
done

log_info "Found /git/current, waiting for docs directory..."
while [ ! -d "$SOURCE_DIR/en" ]; do
    sleep 2
done

log_info "Repository found."

# Initial build
build_docs

# Store initial commit hash
last_commit=$(get_commit_hash)
log_info "Current version: $last_commit"
log_info "Watching for changes (polling every ${POLL_INTERVAL}s)..."

# Poll for commit changes
while true; do
    sleep "$POLL_INTERVAL"

    current_commit=$(get_commit_hash)

    if [ -n "$current_commit" ] && [ "$current_commit" != "$last_commit" ]; then
        log_info "New version detected: $last_commit -> $current_commit"
        build_docs
        last_commit=$current_commit
    fi
done
