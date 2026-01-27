#!/bin/bash
# Watch for changes using inotify and rebuild documentation
# Uses inotifywait for instant change detection instead of polling

set -e

SOURCE_DIR="/git/current/docs"
BUILD_DIR="/static"
DEBOUNCE_SECONDS=3
PID_FILE="/tmp/build.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

build_docs() {
    log_info "Building documentation..."

    local build_failed=0

    # Build English
    if [ -d "$SOURCE_DIR/en" ]; then
        log_info "Building English docs..."
        if sphinx-build -b html "$SOURCE_DIR/en" "$BUILD_DIR/en" 2>&1; then
            log_info "English docs built successfully."
        else
            log_error "English docs build failed!"
            build_failed=1
        fi
    else
        log_warn "English docs directory not found: $SOURCE_DIR/en"
    fi

    # Build Czech
    if [ -d "$SOURCE_DIR/cs" ]; then
        log_info "Building Czech docs..."
        if sphinx-build -b html "$SOURCE_DIR/cs" "$BUILD_DIR/cs" 2>&1; then
            log_info "Czech docs built successfully."
        else
            log_error "Czech docs build failed!"
            build_failed=1
        fi
    else
        log_warn "Czech docs directory not found: $SOURCE_DIR/cs"
    fi

    if [ $build_failed -eq 0 ]; then
        log_info "Build complete."
    else
        log_error "Build completed with errors."
    fi

    return $build_failed
}

# Debounced build - waits for changes to settle before building
trigger_build() {
    # Kill any pending build trigger
    if [ -f "$PID_FILE" ]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid" 2>/dev/null || true
        fi
    fi

    # Start new debounced build in background
    (
        echo $$ > "$PID_FILE"
        sleep "$DEBOUNCE_SECONDS"
        build_docs
        rm -f "$PID_FILE"
    ) &
}

# Wait for git-sync to clone repo
log_info "Waiting for repository to be synced..."
wait_count=0
while [ ! -d "$SOURCE_DIR" ]; do
    sleep 5
    wait_count=$((wait_count + 1))
    if [ $((wait_count % 12)) -eq 0 ]; then
        log_warn "Still waiting for repository... ($(( wait_count * 5 ))s elapsed)"
    fi
done

# Additional wait for en directory
while [ ! -d "$SOURCE_DIR/en" ]; do
    sleep 2
done

log_info "Repository found at $SOURCE_DIR"

# Initial build
build_docs

# Create marker file to indicate ready state (for health checks)
touch /tmp/docs-ready

log_info "Starting inotify watch on $SOURCE_DIR"
log_info "Watching for changes in *.md, *.rst, *.py files..."

# Watch for changes using inotifywait
# -m: monitor mode (run indefinitely)
# -r: recursive
# -e: events to watch (modify, create, delete, move, moved_to, moved_from)
# --include: only watch specific file patterns
inotifywait -m -r \
    -e modify \
    -e create \
    -e delete \
    -e move \
    -e moved_to \
    -e moved_from \
    --include '\.(md|rst|py)$' \
    "$SOURCE_DIR" 2>/dev/null |
while read -r directory event filename; do
    log_info "Change detected: $filename ($event)"
    trigger_build
done
