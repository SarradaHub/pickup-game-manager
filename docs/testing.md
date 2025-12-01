# Testing Guide

## Introduction

This guide covers testing practices for the Pickup Game Manager application. We use RSpec as our testing framework and aim for **80% code coverage** as a baseline. However, coverage is a tool to find gaps, not the only measure of test quality.

### Why Testing Matters

- **Confidence**: Tests give us confidence that our code works as expected
- **Documentation**: Tests serve as living documentation of how the code behaves
- **Refactoring Safety**: Good tests allow us to refactor with confidence
- **Bug Prevention**: Tests catch bugs before they reach production

### Coverage Goals

Our target is **80% code coverage**, but remember:
- **80% is a starting point**, not an end goal
- **Coverage shows what's NOT tested**, not what IS tested well
- **Prioritize critical paths** over achieving 100% coverage
- **Test behavior, not implementation** - high coverage with poor tests is worse than lower coverage with good tests

## Running Tests

### Basic Commands

```bash
# Run all tests
bundle exec rspec

# Run specific file
bundle exec rspec spec/models/payment_spec.rb

# Run specific test
bundle exec rspec spec/models/payment_spec.rb:10

# Run tests in watch mode (requires guard or similar)
bundle exec rspec --watch

# Run tests with documentation format
bundle exec rspec --format documentation
```

### Using Test Scripts

```bash
# Run tests using the provided script
./script/run_tests.sh

# Run tests with database reset
./script/run_tests.sh --reset

# Run tests in parallel
./script/run_tests.sh --parallel
```

### Docker Workflow

```bash
# Run tests in Docker container
docker-compose -f docker-compose.test.yml run --rm test bundle exec rspec
```

## Coverage Reports

### Generating Coverage Reports

Coverage is automatically generated when running tests. After running tests, you can view the coverage report:

```bash
# Open HTML coverage report
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
```

### Understanding Coverage Reports

The coverage report shows:
- **Line Coverage**: Percentage of lines executed
- **Branch Coverage**: Percentage of branches (if/else, case) executed
- **File-by-file breakdown**: See which files need more tests

### Coverage Thresholds

Our coverage configuration enforces:
- **Minimum 80% overall coverage**
- **Minimum 80% per-file coverage**

If coverage falls below these thresholds, the test suite will fail.

## Writing Tests

### Test Structure

RSpec uses `describe`, `context`, and `it` blocks to organize tests:

```ruby
require "rails_helper"

RSpec.describe Payment, type: :model do
  describe "associations" do
    it "belongs to an athlete" do
      # test code
    end
  end

  context "with valid attributes" do
    it "saves successfully" do
      # test code
    end
  end
end
```

### Model Tests

Test models for:
- **Associations**: `belongs_to`, `has_many`, etc.
- **Validations**: Required fields, format validations
- **Methods**: Business logic, calculations
- **Scopes**: Query methods

Example:

```ruby
RSpec.describe Payment, type: :model do
  fixtures :payments, :athletes, :matches

  describe "associations" do
    it "belongs to an athlete" do
      payment = payments(:weekend_payment)
      expect(payment.athlete).to be_an(Athlete)
    end
  end

  describe "validations" do
    it "requires an amount" do
      payment = Payment.new(amount: nil)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to be_present
    end
  end
end
```

### Controller Tests

Test controllers for:
- **HTTP responses**: Status codes, redirects
- **Authentication/Authorization**: Access control
- **Data handling**: Params, session, cookies
- **Rendering**: Views, JSON responses

Example:

```ruby
RSpec.describe PaymentsController, type: :controller do
  fixtures :payments, :athletes

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new payment" do
        expect {
          post :create, params: { payment: valid_attributes }
        }.to change(Payment, :count).by(1)
      end
    end
  end
end
```

### Service Tests

Test services for:
- **Business logic**: Core functionality
- **Error handling**: Edge cases, invalid inputs
- **Side effects**: Database changes, external API calls

### Using Fixtures

We use Rails fixtures for test data. Fixtures are defined in `spec/fixtures/`:

```ruby
# In your test
fixtures :payments, :athletes, :matches

# Use fixtures
payment = payments(:weekend_payment)
athlete = athletes(:john_doe)
```

### Using Factories (FactoryBot)

For more complex test data, consider using FactoryBot:

```ruby
# Create a payment
payment = create(:payment)

# Create with attributes
payment = create(:payment, amount: 20.0, status: "pending")

# Build without saving
payment = build(:payment)
```

## Best Practices

### 1. Test Behavior, Not Implementation

**Bad:**
```ruby
it "calls the calculate method" do
  expect(payment).to receive(:calculate)
  payment.process
end
```

**Good:**
```ruby
it "calculates the correct total" do
  payment = create(:payment, amount: 15.0)
  expect(payment.total).to eq(15.0)
end
```

### 2. Use Descriptive Test Names

**Bad:**
```ruby
it "works" do
```

**Good:**
```ruby
it "calculates equilibrium point for daily income" do
```

### 3. Test Edge Cases

Always test:
- **Empty/nil values**
- **Boundary conditions**
- **Invalid inputs**
- **Error conditions**

Example:

```ruby
describe "edge cases" do
  it "handles zero income gracefully" do
    result = described_class.calculate_equilibrium_point(["non_existent"])
    expect(result).to eq(0)
  end

  it "handles very large numbers" do
    expect {
      described_class.calculate_equilibrium_point(["daily"], %w(Basic Intermediary Advanced))
    }.not_to raise_error
  end
end
```

### 4. Keep Tests Independent

Each test should be able to run in isolation:
- Use `before(:each)` for setup, not `before(:all)`
- Clean up after tests (Rails transactional fixtures handle this)
- Don't rely on test execution order

### 5. Use Appropriate Test Types

- **Unit tests**: Fast, test individual components
- **Integration tests**: Test component interactions
- **System tests**: Test full user workflows (slower)

### 6. Focus on Critical Paths

Prioritize testing:
- **Business-critical functionality**
- **User-facing features**
- **Complex calculations**
- **Error-prone areas**

## Coverage Best Practices

Based on [Google's Code Coverage Best Practices](https://testing.googleblog.com/2020/08/code-coverage-best-practices.html):

1. **Use coverage to find gaps**: Coverage tells you what's NOT tested, not what IS tested well
2. **Don't chase 100%**: Some code (like error handlers) may not need full coverage
3. **Focus on meaningful coverage**: Test critical paths and edge cases
4. **Avoid testing implementation details**: Test behavior, not how it's implemented
5. **Use coverage as a guide**: It's one metric among many

## CI Integration

### GitHub Actions

Coverage is automatically generated in CI. The workflow:
1. Sets up Ruby and PostgreSQL
2. Installs dependencies
3. Prepares the test database
4. Runs RSpec with coverage
5. Uploads coverage artifacts

### Viewing CI Coverage

Coverage reports are available as CI artifacts. Download and open `coverage/index.html` to view the report.

## Troubleshooting

### Tests Fail with Coverage Below 80%

1. Check which files have low coverage
2. Review the coverage report: `open coverage/index.html`
3. Add tests for uncovered code
4. Consider if the code should be excluded (add to SimpleCov filters)

### Database Issues

```bash
# Reset test database
RAILS_ENV=test bundle exec rails db:reset

# Or use the script
./script/run_tests.sh --reset
```

### Slow Tests

- Use `let` instead of `let!` when possible
- Avoid unnecessary database queries
- Use `build` instead of `create` when you don't need persistence
- Consider parallel test execution

### Coverage Not Generating

- Ensure SimpleCov is required at the top of `spec_helper.rb`
- Check that `coverage/` directory is not in `.gitignore` (it should be)
- Verify SimpleCov gem is in the Gemfile

## Resources

- [RSpec Documentation](https://rspec.info/)
- [RSpec Rails Guide](https://rspec.info/documentation/rails/)
- [SimpleCov Documentation](https://github.com/simplecov-ruby/simplecov)
- [Google Testing Blog - Code Coverage Best Practices](https://testing.googleblog.com/2020/08/code-coverage-best-practices.html)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)

## Questions?

If you have questions about testing or need help writing tests, reach out to the team or check the existing test files for examples.

