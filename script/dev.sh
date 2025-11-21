#!/bin/bash

# Development environment management script using docker-compose
# Usage:
#   ./script/dev.sh start          # Start development environment
#   ./script/dev.sh stop           # Stop development environment
#   ./script/dev.sh restart        # Restart development environment
#   ./script/dev.sh build          # Build containers
#   ./script/dev.sh logs           # View logs
#   ./script/dev.sh console        # Open Rails console
#   ./script/dev.sh db:migrate     # Run database migrations
#   ./script/dev.sh db:seed        # Seed database
#   ./script/dev.sh clean          # Clean up containers and volumes

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

# Compose file for development
COMPOSE_FILE="-f docker-compose.yml"

# Build docker-compose command
compose_cmd() {
    if [ "$DOCKER_COMPOSE" = "docker compose" ]; then
        docker compose $COMPOSE_FILE "$@"
    else
        docker-compose $COMPOSE_FILE "$@"
    fi
}

# Run command in docker container
docker_cmd() {
    compose_cmd exec app "$@"
}

# Check if container is running
is_container_running() {
    local container_name="${1:-pgm-app}"
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$" && return 0 || return 1
}

# Check if database is ready
is_database_ready() {
    compose_cmd exec -T db pg_isready -U lmafra -d pickup_game_manager_development &> /dev/null && return 0 || return 1
}

# Wait for container
wait_for_container() {
    local container_name="${1:-pgm-app}"
    local max_attempts=30
    local attempt=1
    
    step "Waiting for container '$container_name' to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if is_container_running "$container_name"; then
            info "Container is ready ✓"
            return 0
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    echo ""
    error "Container '$container_name' failed to start after $max_attempts seconds"
    return 1
}

# Wait for database
wait_for_database() {
    local max_attempts=30
    local attempt=1
    
    step "Waiting for database to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if is_database_ready; then
            info "Database is ready ✓"
            return 0
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    echo ""
    error "Database failed to become ready after $max_attempts seconds"
    return 1
}

# Check if containers are running
containers_running() {
    compose_cmd ps --services --filter "status=running" 2>/dev/null | grep -q . && return 0 || return 1
}

# Start development environment
start_dev() {
    step "Starting development environment..."
    
    if containers_running; then
        info "Containers are already running"
        return 0
    fi
    
    compose_cmd up -d
    wait_for_container
    wait_for_database
    
    info "Development environment is ready!"
    info "Application is available at: http://localhost:3000"
    info ""
    info "Useful commands:"
    info "  ./script/dev.sh logs          # View logs"
    info "  ./script/dev.sh console       # Open Rails console"
    info "  ./script/dev.sh stop         # Stop containers"
}

# Stop development environment
stop_dev() {
    step "Stopping development environment..."
    compose_cmd stop
    info "Development environment stopped ✓"
}

# Restart development environment
restart_dev() {
    step "Restarting development environment..."
    compose_cmd restart
    wait_for_container
    wait_for_database
    info "Development environment restarted ✓"
}

# Build containers
build_dev() {
    local no_cache="${1:-}"
    step "Building containers..."
    if [ "$no_cache" = "--no-cache" ]; then
        compose_cmd build --no-cache
    else
        compose_cmd build
    fi
    info "Containers built ✓"
}

# View logs
view_logs() {
    local service="${1:-}"
    if [ -n "$service" ]; then
        compose_cmd logs -f "$service"
    else
        compose_cmd logs -f
    fi
}

# Open Rails console
open_console() {
    if ! is_container_running "pgm-app"; then
        error "Container is not running. Start it first with: ./script/dev.sh start"
        exit 1
    fi
    docker_cmd bundle exec rails console
}

# Run Rails command
run_rails_command() {
    local command="$*"
    if ! is_container_running "pgm-app"; then
        error "Container is not running. Start it first with: ./script/dev.sh start"
        exit 1
    fi
    docker_cmd bundle exec rails "$command"
}

# Show status
show_status() {
    step "Development environment status:"
    echo ""
    compose_cmd ps
    echo ""
    
    if is_container_running "pgm-app"; then
        info "Application: Running at http://localhost:3000"
    else
        warn "Application: Not running"
    fi
    
    if is_database_ready; then
        info "Database: Ready"
    else
        warn "Database: Not ready"
    fi
}

# Clean up containers and volumes
clean_dev() {
    step "Cleaning up development environment..."
    warn "This will remove containers, volumes, and data!"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        compose_cmd down --volumes --remove-orphans
        info "Development environment cleaned up ✓"
    else
        info "Cleanup cancelled"
    fi
}

# Show help
show_help() {
    cat << EOF
Development Environment Management Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  start              Start development environment (default)
  stop               Stop development environment
  restart            Restart development environment
  build [--no-cache] Build containers (use --no-cache for clean build)
  logs [service]     View logs (optionally for specific service)
  console            Open Rails console
  status             Show status of containers
  clean              Clean up containers and volumes (destructive!)
  shell              Open shell in app container
  db:*               Run database commands (migrate, seed, create, etc.)
  rails:*            Run any Rails command

Examples:
  $0 start                    # Start development environment
  $0 stop                     # Stop development environment
  $0 restart                  # Restart everything
  $0 build                    # Build containers
  $0 build --no-cache         # Clean build
  $0 logs                     # View all logs
  $0 logs app                 # View app logs only
  $0 console                  # Open Rails console
  $0 db:migrate               # Run migrations
  $0 db:seed                  # Seed database
  $0 db:create                # Create database
  $0 db:reset                 # Reset database
  $0 rails routes              # Show routes
  $0 rails runner "puts 'Hello'"  # Run Ruby code
  $0 shell                    # Open shell in container
  $0 status                   # Show status
  $0 clean                    # Clean up everything

Environment:
  The development environment runs on http://localhost:3000
  Database is accessible on localhost:5432
EOF
}

# Main command handler
main() {
    # Check if we're in the project directory
    if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
        error "docker-compose.yml not found. Are you in the project root?"
        exit 1
    fi

    cd "$PROJECT_DIR"

    # Parse command
    local command="${1:-start}"
    shift || true

    case "$command" in
        start|up)
            start_dev
            ;;
        stop|down)
            stop_dev
            ;;
        restart)
            restart_dev
            ;;
        build)
            build_dev "$@"
            ;;
        logs)
            view_logs "$@"
            ;;
        console|c)
            open_console
            ;;
        shell|sh)
            if ! is_container_running "pgm-app"; then
                error "Container is not running. Start it first with: ./script/dev.sh start"
                exit 1
            fi
            docker_cmd bash
            ;;
        status|ps)
            show_status
            ;;
        clean)
            clean_dev
            ;;
        db:*)
            run_rails_command "$command"
            ;;
        rails:*)
            run_rails_command "${command#rails:}"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            # Try to run as Rails command
            if [[ "$command" =~ ^(db:|rails:).* ]]; then
                run_rails_command "${command#*:}"
            else
                # Try to run as direct Rails command
                run_rails_command "$command" "$@"
            fi
            ;;
    esac
}

# Run main function
main "$@"
