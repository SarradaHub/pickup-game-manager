## Pickup Game Manager

A Rails 8 app for managing pickup games, athletes, match attendance, and cashflow (payments, incomes, expenses). It includes a dashboard summarizing revenue, costs, and profit, plus a simple tool to estimate the equilibrium point (break-even) given selected income and expense categories.

### What the app does
- **Athletes**: Create athletes with `name`, `phone`, and `date_of_birth`. Track their attendance to matches.
- **Matches**: Schedule matches with `date` and `location`. Link athletes to matches and record payments per athlete/match.
- **Payments**: Record payments from athletes for a specific match and category (e.g., modality). Payments have `amount` and `status` (`pending` or `paid`).
- **Incomes**: Define income entries tied to a `TransactionCategory` with a `unit_value` and `date`.
- **Expenses**: Track expenses with `type`, `description`, `unit_value`, `quantity`, and `date`. Total per expense is `unit_value * quantity`.
- **Transaction Categories**: Centralize categories used by `Incomes` and `Payments` (e.g., modality names).
- **Dashboard**: At `/` or `/dashboard`, shows period summaries: total paid income, total expenses, and profit for the selected date range.

### Tech stack
- Rails 8, Ruby 3.3
- PostgreSQL
- Docker & Docker Compose (for development)
- Importmap, Turbo, Stimulus
- RSpec for tests
- Brakeman & RubyCritic for code quality

---

## Getting Started

### Quick Start with Docker (Recommended)

1. **Prerequisites:** Docker and Docker Compose installed

2. **Setup:**
   ```bash
   # Copy environment file
   cp env.example .env
   
   # Start development environment
   ./script/dev.sh start    # Unix/Linux/macOS
   script\dev.bat start     # Windows
   ```

3. **Access:** http://localhost:3000

The database will be automatically created and migrated on first start.

### Local Development (Without Docker)

1. **Prerequisites:** Ruby 3.3, Bundler, PostgreSQL

2. **Setup:**
   ```bash
   cp env.example .env
   bundle install
   bin/rails db:create db:migrate db:seed
   bin/rails server
   ```

---

## Available Scripts

The project includes helper scripts for common development tasks. All scripts work with Docker (if containers are running) or locally.

### Development Script (`script/dev.sh` / `script/dev.bat`)

Manage your development environment:

```bash
./script/dev.sh start          # Start containers
./script/dev.sh stop           # Stop containers
./script/dev.sh restart        # Restart containers
./script/dev.sh build           # Build containers
./script/dev.sh logs            # View logs
./script/dev.sh console         # Open Rails console
./script/dev.sh shell           # Open shell in container
./script/dev.sh status          # Show container status

# Database commands
./script/dev.sh db:migrate      # Run migrations
./script/dev.sh db:seed         # Seed database
./script/dev.sh db:create       # Create database
./script/dev.sh db:reset        # Reset database

# Rails commands
./script/dev.sh rails routes    # Show routes
./script/dev.sh rails runner "puts 'Hello'"  # Run Ruby code
```

### Test Script (`script/run_tests.sh` / `script/run_tests.bat`)

Run RSpec tests with optimized options:

```bash
# Basic usage
./script/run_tests.sh                    # Run all tests (fast, no reset)
./script/run_tests.sh spec/models        # Run specific directory
./script/run_tests.sh spec/models/athlete_spec.rb  # Run specific file

# Speed options
./script/run_tests.sh --skip-checks      # Fastest: skip health checks
./script/run_tests.sh --reset            # Fast reset (recommended)
./script/run_tests.sh --keep-containers   # Keep containers running

# Advanced options
./script/run_tests.sh --parallel         # Run tests in parallel
./script/run_tests.sh --full-reset       # Full database reset
./script/run_tests.sh --reset-docker     # Reset and rebuild containers

# RSpec options (passed directly to RSpec)
./script/run_tests.sh --format documentation  # Use documentation formatter
./script/run_tests.sh --fail-fast             # Stop on first failure
./script/run_tests.sh --seed 12345            # Set random seed
```

**Common options:**
- `--reset` / `-r`: Fast database reset (truncate)
- `--no-reset` / `-n`: Skip reset (default, fastest)
- `--skip-checks` / `-s`: Skip container health checks
- `--keep-containers` / `-k`: Keep containers running after tests
- `--parallel` / `-p`: Run tests in parallel

### Code Quality Script (`script/run_code_quality.sh`)

Run static analysis and code quality checks:

```bash
./script/run_code_quality.sh brakeman    # Security scan (Brakeman)
./script/run_code_quality.sh rubycritic  # Code quality analysis
./script/run_code_quality.sh all         # Run both tools
```

**What each tool does:**
- **Brakeman**: Scans for security vulnerabilities in Rails code
- **RubyCritic**: Analyzes code quality, complexity, and provides a score (HTML report in `tmp/rubycritic/`)

You can also use the tools directly:
```bash
bin/brakeman              # Security scan
bin/rubycritic app lib    # Code quality analysis
bin/rubocop               # Code style check
```

---

## Code Quality & Static Analysis

The project includes automated code quality checks that run in CI and can be run locally.

### Tools

- **Brakeman**: Security vulnerability scanner for Rails applications
- **RubyCritic**: Code quality and complexity analysis
- **RuboCop**: Code style and best practices enforcement

### Running Locally

```bash
# Using the helper script (recommended)
./script/run_code_quality.sh all

# Or run individually
bin/brakeman
bin/rubycritic app lib
bin/rubocop
```

### CI Integration

Code quality checks run automatically in GitHub Actions:
- Security scans (Brakeman) on every push/PR
- Code quality analysis (RubyCritic) on every push/PR
- Code style checks (RuboCop) on every push/PR
- Reports are available as downloadable artifacts

---

## Running Tests

### Using Docker (Recommended)

```bash
./script/run_tests.sh              # Fastest: no reset
./script/run_tests.sh --reset      # With database reset
./script/run_tests.sh spec/models  # Run specific tests
```

### Local Testing

```bash
bundle exec rspec
```

---

## Project Structure

### Key Domain Relationships
- `Athlete` has_many `Payments` and participates in `Matches` via `AthleteMatch`
- `Match` has_many `Payments` and has many `Athletes` through `AthleteMatch`
- `Payment` belongs_to `Athlete`, `Match`, and `TransactionCategory`
- `Income` belongs_to `TransactionCategory`
- `Expense` is standalone with computed `total_value`
- `TransactionCategory` has_many `Incomes` and `Payments`

### Services
- `FinancialSummary.period_summary(date_range)`: Returns income, expenses, and profit for a date range
- `EquilibriumPoint.calculate_equilibrium_point(income_types, expenses_types)`: Calculates break-even point

### Routes
- `/`, `/dashboard` → Dashboard
- `/athletes`, `/matches`, `/payments`, `/incomes`, `/expenses` → CRUD endpoints
- `/up` → Health check

---

## Deployment

Containerized deployment via Kamal is configured in `config/deploy.yml`. See the file for deployment setup instructions.

---

## Environment Configuration

- Copy `env.example` to `.env` for local development
- Database configuration: `config/database.yml`
- Default database names: `pickup_game_manager_development` and `pickup_game_manager_test`

---

## Notes

- `Expense` and `Income` disable STI to allow `type` as a normal column for Expenses
- `Payment#modality` maps to its `TransactionCategory` name for convenience
- Test database uses separate volumes in Docker to avoid conflicts with development data
