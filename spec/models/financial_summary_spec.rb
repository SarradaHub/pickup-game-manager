require "rails_helper"

RSpec.describe(FinancialSummary, type: :model) do
  fixtures :payments, :expenses, :transaction_categories

  describe ".period_summary" do
    let(:date_range) { Date.parse("2025-01-01")..Date.parse("2025-12-31") }

    it "returns a hash with all required keys" do
      result = described_class.period_summary(date_range)

      expect(result).to(be_a(Hash))
      expect(result).to(have_key(:income))
      expect(result).to(have_key(:income_value))
      expect(result).to(have_key(:expenses))
      expect(result).to(have_key(:expenses_value))
      expect(result).to(have_key(:profit))
    end

    it "returns income as an array of payments" do
      result = described_class.period_summary(date_range)

      expect(result[:income]).to(be_an(ActiveRecord::Relation))
      expect(result[:income]).to(all(be_a(Payment)))
      expect(result[:income]).to(all(have_attributes(status: "paid")))
    end

    it "returns income_value as a numeric value" do
      result = described_class.period_summary(date_range)

      expect(result[:income_value]).to(be_a(Numeric))
      expect(result[:income_value]).to(be >= 0)
    end

    it "returns expenses as an array of expenses" do
      result = described_class.period_summary(date_range)

      expect(result[:expenses]).to(be_an(ActiveRecord::Relation))
      expect(result[:expenses]).to(all(be_an(Expense)))
    end

    it "returns expenses_value as a numeric value" do
      result = described_class.period_summary(date_range)

      expect(result[:expenses_value]).to(be_a(Numeric))
      expect(result[:expenses_value]).to(be >= 0)
    end

    it "returns profit as a numeric value" do
      result = described_class.period_summary(date_range)

      expect(result[:profit]).to(be_a(Numeric))
    end

    it "calculates profit correctly as income minus expenses" do
      result = described_class.period_summary(date_range)

      expected_profit = result[:income_value] - result[:expenses_value]
      expect(result[:profit]).to(eq(expected_profit))
    end
  end

  describe "with specific date ranges" do
    it "handles empty date ranges" do
      empty_range = Date.parse("2025-01-01")..Date.parse("2025-01-01")
      result = described_class.period_summary(empty_range)

      expect(result[:income]).to(be_empty)
      expect(result[:income_value]).to(eq(0))
      expect(result[:expenses]).to(be_empty)
      expect(result[:expenses_value]).to(eq(0))
      expect(result[:profit]).to(eq(0))
    end

    it "handles date ranges with no data" do
      future_range = Date.parse("2030-01-01")..Date.parse("2030-12-31")
      result = described_class.period_summary(future_range)

      expect(result[:income]).to(be_empty)
      expect(result[:income_value]).to(eq(0))
      expect(result[:expenses]).to(be_empty)
      expect(result[:expenses_value]).to(eq(0))
      expect(result[:profit]).to(eq(0))
    end

    it "handles date ranges with only income" do
      # Create a date range that only includes income data
      income_only_range = Date.parse("2025-08-30")..Date.parse("2025-09-05")
      result = described_class.period_summary(income_only_range)

      expect(result[:income]).not_to(be_empty)
      expect(result[:income_value]).to(be > 0)
      expect(result[:expenses]).to(be_empty)
      expect(result[:expenses_value]).to(eq(0))
      expect(result[:profit]).to(eq(result[:income_value]))
    end

    it "handles date ranges with only expenses" do
      # Create a date range that only includes expense data
      expense_only_range = Date.parse("2025-08-10")..Date.parse("2025-08-25")
      result = described_class.period_summary(expense_only_range)

      expect(result[:income]).to(be_empty)
      expect(result[:income_value]).to(eq(0))
      expect(result[:expenses]).not_to(be_empty)
      expect(result[:expenses_value]).to(be > 0)
      expect(result[:profit]).to(eq(-result[:expenses_value]))
    end
  end

  describe "data accuracy" do
    let(:date_range) { Date.parse("2025-01-01")..Date.parse("2025-12-31") }

    it "correctly calculates income value from payments" do
      result = described_class.period_summary(date_range)
      expected_income = Payment.where(date: date_range, status: "paid").sum(:amount)

      expect(result[:income_value]).to(eq(expected_income))
    end

    it "correctly calculates expenses value from expenses" do
      result = described_class.period_summary(date_range)
      expected_expenses = Expense.where(date: date_range).sum { |expense| expense.unit_value * expense.quantity }

      expect(result[:expenses_value]).to(eq(expected_expenses))
    end

    it "returns the correct number of income records" do
      result = described_class.period_summary(date_range)
      expected_count = Payment.where(date: date_range, status: "paid").count

      expect(result[:income].count).to(eq(expected_count))
    end

    it "returns the correct number of expense records" do
      result = described_class.period_summary(date_range)
      expected_count = Expense.where(date: date_range).count

      expect(result[:expenses].count).to(eq(expected_count))
    end
  end

  describe "edge cases" do
    it "handles nil date range gracefully" do
      result = described_class.period_summary(nil)

      expect(result).to(be_a(Hash))
      expect(result[:income]).to(be_empty)
      expect(result[:income_value]).to(eq(0.0))
      expect(result[:expenses]).to(be_empty)
      expect(result[:expenses_value]).to(eq(0))
      expect(result[:profit]).to(eq(0.0))
    end

    it "handles invalid date range gracefully" do
      invalid_range = "invalid".."range"
      result = described_class.period_summary(invalid_range)

      expect(result).to(be_a(Hash))
      expect(result[:income]).to(be_empty)
      expect(result[:income_value]).to(eq(0.0))
      expect(result[:expenses]).to(be_empty)
      expect(result[:expenses_value]).to(eq(0))
      expect(result[:profit]).to(eq(0.0))
    end

    it "handles very large date ranges" do
      large_range = Date.parse("1900-01-01")..Date.parse("2100-12-31")
      result = described_class.period_summary(large_range)

      expect(result).to(be_a(Hash))
      expect(result).to(have_key(:income))
      expect(result).to(have_key(:expenses))
      expect(result).to(have_key(:profit))
    end
  end

  describe "fixtures" do
    it "loads all payment fixtures correctly" do
      expect(payments(:weekend_payment)).to(be_valid)
      expect(payments(:indoor_payment)).to(be_valid)
      expect(payments(:beach_payment)).to(be_valid)
      expect(payments(:night_payment)).to(be_valid)
    end

    it "loads all expense fixtures correctly" do
      expect(expenses(:food)).to(be_valid)
      expect(expenses(:transportation)).to(be_valid)
      expect(expenses(:entertainment)).to(be_valid)
      expect(expenses(:utilities)).to(be_valid)
      expect(expenses(:equipment)).to(be_valid)
    end

    it "has payments with different amounts" do
      amounts = Payment.pluck(:amount)
      expect(amounts).to(include(15.0, 35.0))
    end

    it "has expenses with different types" do
      types = Expense.pluck(:type)
      expect(types).to(include("Basic", "Intermediary", "Advanced"))
    end
  end
end
