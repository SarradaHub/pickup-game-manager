## Pickup Game Manager

A Rails 8 app for managing pickup games, athletes, match attendance, and cashflow (payments, incomes, expenses). It includes a dashboard summarizing revenue, costs, and profit, plus a simple tool to estimate the equilibrium point (break-even) given selected income and expense categories.

### What the app does
- **Athletes**: Create athletes with `name`, `phone`, and `date_of_birth`. Track their attendance to matches.
- **Matches**: Schedule matches with `date` and `location`. Link athletes to matches and record payments per athlete/match.
- **Payments**: Record payments from athletes for a specific match and category (e.g., modality). Payments have `amount` and `status` (`pending` or `paid`).
- **Incomes**: Define income entries tied to a `TransactionCategory` with a `unit_value` and `date`.
- **Expenses**: Track expenses with `type`, `description`, `unit_value`, `quantity`, and `date` (uses STI disabled, so `type` is a normal attribute). Total per expense is `unit_value * quantity`.
- **Transaction Categories**: Centralize categories used by `Incomes` and `Payments` (e.g., modality names). Ensures consistent reporting.
- **Dashboard**: At `/` or `/dashboard`, shows period summaries: total paid income, total expenses, and profit for the selected date range.

### Key domain relationships
- `Athlete has_many Payments` and participates in `Matches` via `AthleteMatch` join model.
- `Match has_many Payments` and has many `Athletes` through `AthleteMatch`.
- `Payment belongs_to Athlete`, `Match`, and `TransactionCategory`.
- `Income belongs_to TransactionCategory`.
- `Expense` is standalone with computed `total_value`.
- `TransactionCategory has_many Incomes` and `Payments`.

### Services
- `FinancialSummary.period_summary(date_range)`:
  - income: all `Payment` records with `status: "paid"` within range
  - income_value: sum of `amount` from those payments
  - expenses: all `Expense` records within range
  - expenses_value: sum of `unit_value * quantity`
  - profit: `income_value - expenses_value`
- `EquilibriumPoint.calculate_equilibrium_point(income_types = [], expenses_types = [])`:
  - For selected income category names and expense types, computes:
    - `equilibrium_point = ceil(expenses_total / income_total)`
    - per-type averages, counts, and totals for both sides
  - Returns an object with totals, per-type breakdowns, counts, and the equilibrium point. Returns zeros if no income data or no selected income types.

### Routes
Resourceful CRUD endpoints are provided for:
- `/athletes`
- `/matches`
- `/payments`
- `/incomes`
- `/expenses`

Additional routes:
- `/dashboard` → `dashboard#index`
- `/` (root) → `dashboard#index`
- `/up` → Rails health check

### Tech stack
- Rails 8, Ruby 3.3 (see `.ruby-version` if present)
- PostgreSQL
- Docker & Docker Compose (for development)
- Importmap, Turbo, Stimulus
- Solid Queue/Cache/Cable (configured gems present)
- RSpec for tests

### Getting started

#### Option 1: Using Docker (Recommended)

The easiest way to get started is using Docker Compose:

1. **Prerequisites:**
   - Docker and Docker Compose installed
   - Git

2. **Setup environment variables:**
   - Copy `env.example` to `.env` (for development) and adjust if needed:
     - `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`

3. **Start development environment:**
   ```bash
   # Unix/Linux/macOS
   ./script/dev.sh start
   
   # Windows
   script\dev.bat start
   ```
   
   This will:
   - Build the Docker containers
   - Start PostgreSQL and Rails
   - Set up the database automatically
   - Make the app available at http://localhost:3000

4. **Access the application:**
   - Visit http://localhost:3000
   - The database will be automatically created and migrated

**Useful development commands:**
```bash
# View logs
./script/dev.sh logs

# Open Rails console
./script/dev.sh console

# Run database migrations
./script/dev.sh db:migrate

# Seed the database
./script/dev.sh db:seed

# Stop containers
./script/dev.sh stop

# Restart containers
./script/dev.sh restart

# View status
./script/dev.sh status
```

#### Option 2: Local Development (Without Docker)

1. **Prerequisites:**
   - Ruby 3.3 and Bundler installed
   - PostgreSQL running and accessible

2. **Setup environment variables:**
   - Copy `env.example` to `.env` and adjust:
     - `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`

3. **Install dependencies:**
   ```bash
   bundle install
   ```

4. **Database setup:**
   ```bash
   bin/rails db:create db:migrate
   ```

5. **Run the app:**
   ```bash
   bin/rails server
   ```
   - Visit http://localhost:3000

### Running tests

#### Using Docker (Recommended)

```bash
# Unix/Linux/macOS
./script/run_tests.sh

# Windows
script\run_tests.bat
```

**Test script options:**
```bash
# Fastest - no reset, skip checks (for quick iterations)
./script/run_tests.sh --skip-checks

# Fast reset when needed (recommended)
./script/run_tests.sh --reset

# Keep containers running for multiple test runs
./script/run_tests.sh --keep-containers --reset

# Run tests in parallel (if parallel_tests gem is installed)
./script/run_tests.sh --parallel

# Run specific test file
./script/run_tests.sh spec/models/athlete_spec.rb

# Full database reset (slower but thorough)
./script/run_tests.sh --full-reset

# Reset Docker containers and rebuild
./script/run_tests.sh --reset-docker
```

**Available options:**
- `--reset` / `-r`: Fast database reset (truncate, recommended)
- `--no-reset` / `-n`: Skip database reset (fastest, default)
- `--skip-checks` / `-s`: Skip container health checks (fastest startup)
- `--keep-containers` / `-k`: Keep containers running after tests
- `--parallel` / `-p`: Run tests in parallel
- `--full-reset` / `-F`: Full database reset (drop/create)
- `--reset-docker` / `-d`: Reset Docker containers and rebuild

#### Local Testing (Without Docker)

```bash
bundle exec rspec
```

### Data model (overview)
- `Athlete(name, phone, date_of_birth)`
- `Match(date, location)`
- `AthleteMatch(athlete_id, match_id)` with uniqueness on `[athlete_id, match_id]`
- `TransactionCategory(name)` unique
- `Payment(athlete_id, match_id, transaction_category_id, amount, status, date)`
- `Income(transaction_category_id, unit_value, date)`
- `Expense(type, description, unit_value, quantity, date)` with `total_value = unit_value * quantity`

### Notable validations and scopes
- Presence validations across core fields (e.g., `Athlete.name`, `Match.date`, `Payment.amount`).
- `Payment.status` limited to `pending` or `paid`; convenience scopes: `.pending` and `.paid`.
- `Expense.quantity` must be greater than 0.
- `AthleteMatch` enforces uniqueness per athlete/match pair.

### Deployment
- Containerized deployment via Kamal is scaffolded in `config/deploy.yml`.
  - Set your image name, server hosts, domain, and registry credentials.
  - Provide secrets (e.g., `RAILS_MASTER_KEY`) via Kamal’s secrets mechanism.
  - Configure DB host and any accessories as needed.

### Environment configuration
- See `config/database.yml` for Postgres env variable usage.
- Default dev/test DB names are derived from env vars; override in `.env`.

### Health and monitoring
- `/up` returns 200 when the app boots successfully, useful for load balancers.

### Notes
- `Expense` and `Income` disable STI by design to allow `type` as a normal column for Expenses and a proxy to `TransactionCategory` name for Incomes.
- `Payment#modality` maps to its `TransactionCategory` name for convenience.
