#!/bin/bash

# Code quality analysis script
# Usage:
#   ./script/run_code_quality.sh brakeman    # Run Brakeman security scan
#   ./script/run_code_quality.sh rubycritic  # Run RubyCritic analysis
#   ./script/run_code_quality.sh all         # Run both

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }

cd "$PROJECT_DIR"

# Detect docker-compose command
detect_docker_compose() {
    if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        error "Neither 'docker compose' nor 'docker-compose' found."
        exit 1
    fi
}

DOCKER_COMPOSE=$(detect_docker_compose)
COMPOSE_FILE="-f docker-compose.yml"

compose_cmd() {
    if [ "$DOCKER_COMPOSE" = "docker compose" ]; then
        docker compose $COMPOSE_FILE "$@"
    else
        docker-compose $COMPOSE_FILE "$@"
    fi
}

docker_cmd() {
    compose_cmd exec app "$@"
}

# Check if running in Docker
is_docker() {
    [ -f "$PROJECT_DIR/docker-compose.yml" ] && compose_cmd ps app &> /dev/null
}

run_brakeman() {
    step "Running Brakeman security scan..."
    echo ""
    
    if is_docker; then
        docker_cmd bundle exec brakeman --no-pager
    else
        bundle exec brakeman --no-pager
    fi
}

run_rubycritic() {
    step "Running RubyCritic code quality analysis..."
    echo ""
    
    if is_docker; then
        docker_cmd bundle exec rubycritic app lib --format html --minimum-score 0
    else
        bundle exec rubycritic app lib --format html --minimum-score 0
    fi
    
    info "RubyCritic report generated in tmp/rubycritic/"
    info "Open tmp/rubycritic/overview.html in your browser to view the report"
}

case "${1:-all}" in
    brakeman)
        run_brakeman
        ;;
    rubycritic)
        run_rubycritic
        ;;
    all)
        run_brakeman
        echo ""
        run_rubycritic
        ;;
    *)
        echo "Usage: $0 [brakeman|rubycritic|all]"
        exit 1
        ;;
esac
