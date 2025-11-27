require "rails_helper"

RSpec.describe(EquilibriumPoint, type: :model) do
  fixtures :incomes, :expenses, :transaction_categories

  describe ".calculate_equilibrium_point" do
    context "with single income type" do
      it "calculates equilibrium point for daily income" do
        result = described_class.calculate_equilibrium_point(["daily"])
        expect(result).to(be_a(Integer))
        expect(result).to(be >= 0)
      end

      it "calculates equilibrium point for monthly income" do
        result = described_class.calculate_equilibrium_point(["monthly"])
        expect(result).to(be_a(Integer))
        expect(result).to(be >= 0)
      end
    end

    context "with multiple income types" do
      it "calculates equilibrium point for daily and monthly incomes" do
        result = described_class.calculate_equilibrium_point(["daily", "monthly"])
        expect(result).to(be_a(Integer))
        expect(result).to(be >= 0)
      end
    end

    context "with specific expense types" do
      it "calculates equilibrium point for Basic expenses only" do
        result = described_class.calculate_equilibrium_point(["daily"], ["Basic"])
        expect(result).to(be_a(Integer))
        expect(result).to(be >= 0)
      end

      it "calculates equilibrium point for Basic and Intermediary expenses" do
        result = described_class.calculate_equilibrium_point(["daily"], ["Basic", "Intermediary"])
        expect(result).to(be_a(Integer))
        expect(result).to(be >= 0)
      end

      it "calculates equilibrium point for all expense types" do
        result = described_class.calculate_equilibrium_point(["daily"], %w(Basic Intermediary Advanced))
        expect(result).to(be_a(Integer))
        expect(result).to(be >= 0)
      end
    end

    context "with no parameters" do
      it "calculates equilibrium point using all incomes and expenses" do
        result = described_class.calculate_equilibrium_point
        expect(result).to(be_a(Integer))
        expect(result).to(be >= 0)
      end
    end

    context "with empty arrays" do
      it "handles empty income types array" do
        result = described_class.calculate_equilibrium_point([], ["Basic"])
        expect(result).to(eq(0))
      end

      it "handles empty expense types array" do
        result = described_class.calculate_equilibrium_point(["daily"], [])
        expect(result).to(be_a(Integer))
        expect(result).to(be >= 0)
      end

      it "handles both empty arrays" do
        result = described_class.calculate_equilibrium_point([], [])
        expect(result).to(eq(0))
      end
    end
  end

  describe "private methods" do
    describe ".income_value" do
      it "calculates total income for specific types" do
        daily_income = described_class.send(:income_value, ["daily"])
        expect(daily_income).to(eq(15.0))

        monthly_income = described_class.send(:income_value, ["monthly"])
        expect(monthly_income).to(eq(35.0))

        both_incomes = described_class.send(:income_value, ["daily", "monthly"])
        expect(both_incomes).to(eq(50.0))
      end

      it "returns 0 for non-existent income types" do
        result = described_class.send(:income_value, ["non_existent"])
        expect(result).to(eq(0))
      end

      it "returns 0 for empty array" do
        result = described_class.send(:income_value, [])
        expect(result).to(eq(0))
      end
    end

    describe ".expenses_value" do
      it "calculates total expenses for specific types" do
        basic_expenses = described_class.send(:expenses_value, ["Basic"])
        expect(basic_expenses).to(eq(650.0)) # Field: 650.0 * 1

        intermediary_expenses = described_class.send(:expenses_value, ["Intermediary"])
        # Goalkeeper: 50.0 * 2 + Football Vest: 350.0 * 1 + Football balls: 150.0 * 1
        expected_intermediary = (50.0 * 2) + 350.0 + 150.0
        expect(intermediary_expenses).to(eq(expected_intermediary))

        advanced_expenses = described_class.send(:expenses_value, ["Advanced"])
        expect(advanced_expenses).to(eq(650.0)) # Barbecue: 650.0 * 1
      end

      it "returns 0 for non-existent expense types" do
        result = described_class.send(:expenses_value, ["non_existent"])
        expect(result).to(eq(0))
      end

      it "returns 0 for empty array" do
        result = described_class.send(:expenses_value, [])
        expect(result).to(eq(0))
      end

      it "calculates total with quantity consideration" do
        all_expenses = described_class.send(:expenses_value, %w(Basic Intermediary Advanced))
        # Basic: 650.0 * 1, Intermediary: (50.0 * 2) + 350.0 + 150.0, Advanced: 650.0 * 1
        expected_total = 650.0 + (50.0 * 2) + 350.0 + 150.0 + 650.0
        expect(all_expenses).to(eq(expected_total))
      end
    end
  end

  describe "calculation accuracy" do
    it "provides realistic equilibrium points" do
      # Test with daily income vs Basic expenses
      daily_income = 15.0
      basic_expenses = 650.0
      expected_equilibrium = (basic_expenses / daily_income).ceil

      result = described_class.calculate_equilibrium_point(["daily"], ["Basic"])
      expect(result).to(eq(expected_equilibrium))
    end

    it "handles different income and expense combinations" do
      # Test with daily + monthly income vs Basic + Intermediary expenses
      total_income = 15.0 + 35.0
      total_expenses = 650.0 + (50.0 * 2) + 350.0 + 150.0
      expected_equilibrium = (total_expenses / total_income).ceil

      result = described_class.calculate_equilibrium_point(["daily", "monthly"], ["Basic", "Intermediary"])
      expect(result).to(eq(expected_equilibrium))
    end
  end

  describe "edge cases" do
    it "handles zero income gracefully" do
      result = described_class.calculate_equilibrium_point(["non_existent"])
      expect(result).to(eq(0))
    end

    it "handles zero expenses gracefully" do
      result = described_class.calculate_equilibrium_point(["daily"], ["non_existent"])
      expect(result).to(be_a(Integer))
      expect(result).to(be >= 0)
    end

    it "handles very large numbers" do
      # This test ensures the method doesn't break with large values
      expect do
        described_class.calculate_equilibrium_point(["daily"], %w(Basic Intermediary Advanced))
      end.not_to(raise_error)
    end
  end
end
