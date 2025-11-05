#!/bin/bash

# Optimized script to run RSpec tests using docker-compose
# Usage:
#   ./script/run_tests.sh                    # Run all tests (fast, no reset)
#   ./script/run_tests.sh --reset-docker     # Reset Docker and DB, then run tests
#   ./script/run_tests.sh --cleanup         # Drop containers after tests
#   ./script/run_tests.sh --reset           # Reset DB (fast truncate)
#   ./script/run_tests.sh --parallel         # Run tests in parallel
#   ./script/run_tests.sh spec/models        # Run specific test directory

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }
debug() { [ "${DEBUG:-}" = "1" ] && echo -e "${CYAN}[DEBUG]${NC} $1" || true; }

# Detect docker-compose command (supports both v1 and v2)
detect_docker_compose() {
    if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        error "Neither 'docker compose' nor 'docker-compose' found. Please install Docker Compose."
        exit 1
    fi
}

DOCKER_COMPOSE=$(detect_docker_compose)
debug "Using: $DOCKER_COMPOSE"

# Compose files for test environment
COMPOSE_FILES="-f docker-compose.yml -f docker-compose.test.yml"

# Build docker-compose command with test config
compose_cmd() {
    if [ "$DOCKER_COMPOSE" = "docker compose" ]; then
        docker compose $COMPOSE_FILES "$@"
    else
        docker-compose $COMPOSE_FILES "$@"
    fi
}

# Run command in docker container with test environment
docker_cmd() {
    compose_cmd exec -T app "$@"
}

# Quick check if container is running (faster than full health check)
is_container_running() {
    local container_name="${1:-pgm-app}"
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$" && return 0 || return 1
}

# Quick check if database is accessible (faster than Rails connection)
is_database_ready() {
    compose_cmd exec -T db pg_isready -U lmafra -d pickup_game_manager_test &> /dev/null && return 0 || return 1
}

# Wait for container (with shorter timeout for faster startup detection)
wait_for_container() {
    local container_name="${1:-pgm-app}"
    local max_attempts=10  # Reduced from 30
    local attempt=1
    
    debug "Waiting for container '$container_name'..."
    while [ $attempt -le $max_attempts ]; do
        if is_container_running "$container_name"; then
            debug "Container is ready"
            return 0
        fi
        sleep 0.5  # Reduced from 1 second
        ((attempt++))
    done
    error "Container '$container_name' failed to start after $((max_attempts / 2)) seconds"
    return 1
}

# Wait for database (optimized)
wait_for_database() {
    local max_attempts=15  # Reduced from 30
    local attempt=1
    
    debug "Waiting for database..."
    while [ $attempt -le $max_attempts ]; do
        if is_database_ready; then
            debug "Database is ready"
            return 0
        fi
        sleep 0.5  # Reduced from 1 second
        ((attempt++))
    done
    error "Database failed to become ready after $((max_attempts / 2)) seconds"
    return 1
}

# Check if containers are running (fast check)
containers_running() {
    compose_cmd ps --services --filter "status=running" 2>/dev/null | grep -q . && return 0 || return 1
}

# Fast database reset using truncate (much faster than drop/create)
reset_database_fast() {
    step "Resetting test database (fast)..."
    docker_cmd bundle exec rails runner <<'EOF' 2>/dev/null || true
conn = ActiveRecord::Base.connection
conn.execute('SET session_replication_role = replica')
tables = conn.tables - ['schema_migrations', 'ar_internal_metadata']
tables.each { |t| conn.execute("TRUNCATE TABLE #{t} RESTART IDENTITY CASCADE") }
conn.execute('SET session_replication_role = DEFAULT')
EOF
    debug "Database reset complete"
}

# Full database reset (only when needed)
reset_database_full() {
    step "Resetting test database (full reset)..."
    docker_cmd bundle exec rails db:drop 2>/dev/null || true
    docker_cmd bundle exec rails db:create
    docker_cmd bundle exec rails db:schema:load
    debug "Database reset complete"
}

# Quick database check (only prepare if needed)
ensure_database_ready() {
    # Quick check - if we can connect, we're good
    if docker_cmd bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" &> /dev/null; then
        debug "Database is ready"
        return 0
    fi
    
    # If not ready, try to prepare
    if docker_cmd bundle exec rails db:test:prepare 2>/dev/null; then
        debug "Database prepared"
        return 0
    fi
    
    # Last resort: load schema
    warn "Database not ready, loading schema..."
    docker_cmd bundle exec rails db:schema:load
}

# Parse arguments
RESET_DB=false  # Changed default - no reset by default for speed
RESET_DOCKER=false
CLEANUP_AFTER=false
KEEP_CONTAINERS=false  # New: keep containers running
PARALLEL=false
FAST_RESET=false
FULL_RESET=false
SKIP_CHECKS=false  # New: skip health checks
TEST_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --reset-docker|-d) 
            RESET_DOCKER=true
            RESET_DB=true
            FULL_RESET=true
            shift
            ;;
        --reset|-r)
            RESET_DB=true
            FAST_RESET=true
            shift
            ;;
        --full-reset|-F)
            RESET_DB=true
            FULL_RESET=true
            shift
            ;;
        --cleanup|-c) 
            CLEANUP_AFTER=true
            shift
            ;;
        --no-reset|-n) 
            RESET_DB=false
            shift
            ;;
        --fast-reset|-f)
            RESET_DB=true
            FAST_RESET=true
            shift
            ;;
        --keep-containers|-k)
            KEEP_CONTAINERS=true
            shift
            ;;
        --skip-checks|-s)
            SKIP_CHECKS=true
            shift
            ;;
        --parallel|-p)
            PARALLEL=true
            shift
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS] [RSPEC_OPTIONS] [TEST_PATH]

Speed Options:
  --no-reset, -n         Skip database reset (default, fastest)
  --reset, -r            Fast database reset (truncate, recommended)
  --full-reset, -F       Full database reset (drop/create, slower)
  --skip-checks, -s      Skip container health checks (fastest startup)
  --keep-containers, -k  Keep containers running after tests

Other Options:
  --reset-docker, -d     Reset Docker containers/volumes and test database
  --cleanup, -c          Drop containers after tests complete
  --parallel, -p         Run tests in parallel (requires parallel_tests gem)
  --help, -h             Show this help

RSpec Options:
  Any additional arguments are passed directly to RSpec:
    --format documentation    # Use documentation formatter
    --seed 12345              # Set random seed
    --fail-fast               # Stop on first failure
    --tag focus               # Run only focused tests

Examples:
  $0                                    # Fastest: no reset, skip checks
  $0 --reset                            # Fast reset (recommended)
  $0 --skip-checks spec/models          # Skip checks, run specific tests
  $0 --keep-containers                  # Keep containers for next run
  $0 --parallel                         # Run tests in parallel
  $0 --format documentation             # Use documentation formatter
EOF
            exit 0
            ;;
        *)
            TEST_ARGS+=("$1")
            shift
            ;;
    esac
done

# Check if we're in the project directory
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ] || [ ! -f "$PROJECT_DIR/docker-compose.test.yml" ]; then
    error "docker-compose files not found. Are you in the project root?"
    exit 1
fi

cd "$PROJECT_DIR"

# Reset Docker if requested
if [ "$RESET_DOCKER" = true ]; then
    step "Resetting Docker containers..."
    compose_cmd down --volumes --remove-orphans 2>/dev/null || true
    compose_cmd build app  # Removed --no-cache for faster builds
    compose_cmd up -d
    if [ "$SKIP_CHECKS" != true ]; then
        wait_for_container
        wait_for_database
    fi
fi

# Ensure containers are running (fast path)
if ! is_container_running "pgm-app"; then
    if containers_running; then
        debug "Containers are starting..."
    else
        step "Starting containers..."
        compose_cmd up -d
    fi
    
    if [ "$SKIP_CHECKS" != true ]; then
        wait_for_container
        wait_for_database
    else
        # Minimal wait for containers to start
        sleep 2
    fi
fi

# Database operations (optimized)
if [ "$RESET_DB" = true ]; then
    if [ "$FULL_RESET" = true ]; then
        reset_database_full
    else
        reset_database_fast
    fi
elif [ "$SKIP_CHECKS" != true ]; then
    # Only check database if we're not skipping checks
    ensure_database_ready
fi

# Build RSpec command
RSPEC_CMD="bundle exec rspec"

# Add parallel option if requested
if [ "$PARALLEL" = true ]; then
    if docker_cmd bundle exec parallel_rspec --version &> /dev/null; then
        RSPEC_CMD="bundle exec parallel_rspec"
        info "Running tests in parallel mode"
    else
        warn "parallel_tests gem not found. Running normally."
        PARALLEL=false
    fi
fi

# Run tests
step "Running RSpec tests..."
echo ""

# Pass all test arguments to RSpec
if [ ${#TEST_ARGS[@]} -eq 0 ]; then
    docker_cmd $RSPEC_CMD
else
    docker_cmd $RSPEC_CMD "${TEST_ARGS[@]}"
fi

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    info "All tests passed! ✓"
else
    error "Tests failed. Exit code: $EXIT_CODE"
fi

# Cleanup if requested (but respect keep-containers)
if [ "$CLEANUP_AFTER" = true ] && [ "$KEEP_CONTAINERS" != true ]; then
    echo ""
    step "Cleaning up Docker containers..."
    compose_cmd down --volumes --remove-orphans 2>/dev/null || true
    info "Containers cleaned up ✓"
elif [ "$KEEP_CONTAINERS" = true ]; then
    info "Containers kept running for next test run ✓"
fi

exit $EXIT_CODE