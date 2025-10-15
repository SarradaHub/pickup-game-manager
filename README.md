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
- Importmap, Turbo, Stimulus
- Solid Queue/Cache/Cable (configured gems present)
- RSpec for tests

### Getting started
1. Prerequisites:
   - Ruby and Bundler installed
   - PostgreSQL running and accessible
2. Setup environment variables:
   - Copy `env.example` to `.env` (for development) and adjust:
     - `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
3. Install dependencies:
   - `bundle install`
4. Database setup:
   - `bin/rails db:create db:migrate`
5. Run the app:
   - `bin/rails server`
   - Visit http://localhost:3000

### Running tests
- `bundle exec rspec`

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
