# Pickup Game Manager

Pickup Game Manager is a Rails 8 application that tracks pickup matches, athlete attendance, and the cashflow that keeps games running. Organizers can schedule matches, register athlete payments, monitor recurring expenses, and review profitability through a unified dashboard.

## Highlights

- Manage athletes with personal details, attendance history, and linked payments.
- Schedule matches, assign participants, and mark payment status by athlete.
- Record incomes and expenses using shared transaction categories for consistent reporting.
- Visualize revenue, cost, and profit over time through the `/dashboard` view.
- Estimate the equilibrium point for any combination of income and expense categories.

## Tech Stack

- Ruby 3.3 with Rails 8, Turbo, and Stimulus.
- PostgreSQL for persistence, managed locally with Docker Compose or direct connections.
- RSpec, Brakeman, RubyCritic, and RuboCop for testing and quality.
- Kamal scripts for deployment automation.

## Quick Start

### Docker Workflow

1. Requirements: Docker and Docker Compose.
2. Copy the environment template and start the stack:
   ```bash
   cp .env.example .env
   ./script/dev.sh start          # macOS/Linux
   script\dev.bat start           # Windows
   ```
3. Visit `http://localhost:3000` to access the dashboard. The database is created and migrated automatically on first boot.

### Local Development (No Docker)

1. Requirements: Ruby 3.3, Bundler, PostgreSQL.
2. Configure environment variables and install dependencies:
   ```bash
   cp .env.example .env
   bundle install
   ```
3. Prepare the database and start Rails:
   ```bash
   bin/rails db:create db:migrate db:seed
   bin/rails server
   ```

## Developer Tooling

- `./script/dev.sh`: Manage Docker services and run Rails commands (status, logs, console, migrations).
- `./script/run_tests.sh`: Execute RSpec suites locally or inside containers with optional reset, parallel, and health check flags.
- `./script/run_code_quality.sh`: Run Brakeman, RubyCritic, or both in one step.

## Testing and Quality

- Run the full test suite with `bundle exec rspec` or `./script/run_tests.sh`.
- Security scans via `bin/brakeman`.
- Code metrics through `bin/rubycritic app lib`.
- Style checks with `bin/rubocop`.

## Domain Model

- `Athlete` participates in matches through `AthleteMatch` and owns payment records.
- `Match` links to many athletes and tracks payments by transaction category.
- `Income` and `Expense` entries rely on shared `TransactionCategory` definitions.
- `FinancialSummary` aggregates cashflow over custom date ranges, while `EquilibriumPoint` calculates the break even threshold.

## Deployment Notes

- Review `config/deploy.yml` for Kamal deployment targets.
- Ensure required environment variables and database credentials are configured on the destination host.
- Maintain environment specific settings in `.env` files and keep secrets out of version control.