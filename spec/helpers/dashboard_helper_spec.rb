require "rails_helper"

RSpec.describe(DashboardHelper, type: :helper) do
  describe "#calculate_bar_height" do
    context "with normal values" do
      it "calculates percentage correctly" do
        expect(helper.calculate_bar_height(50, 100)).to(eq(50.0))
      end

      it "rounds to 1 decimal place" do
        expect(helper.calculate_bar_height(33, 100)).to(eq(33.0))
        expect(helper.calculate_bar_height(33.333, 100)).to(eq(33.3))
      end

      it "handles values less than total" do
        expect(helper.calculate_bar_height(25, 100)).to(eq(25.0))
      end

      it "handles values equal to total" do
        expect(helper.calculate_bar_height(100, 100)).to(eq(100.0))
      end
    end

    context "with edge cases" do
      it "returns 0 when total is zero" do
        expect(helper.calculate_bar_height(50, 0)).to(eq(0))
      end

      it "caps at 100% when value exceeds total" do
        expect(helper.calculate_bar_height(150, 100)).to(eq(100.0))
      end

      it "handles zero value" do
        expect(helper.calculate_bar_height(0, 100)).to(eq(0.0))
      end

      it "handles negative values (results in negative percentage)" do
        # The method doesn't clamp negative values, it just calculates the percentage
        expect(helper.calculate_bar_height(-10, 100)).to(eq(-10.0))
      end

      it "handles very large values" do
        expect(helper.calculate_bar_height(1000, 100)).to(eq(100.0))
      end

      it "handles decimal values" do
        expect(helper.calculate_bar_height(33.5, 100)).to(eq(33.5))
      end

      it "handles string values that can be converted to numbers" do
        # The method calls .to_f on values, but .zero? on total requires a numeric
        # This will raise an error if total is a string, so we test with numeric strings for value only
        expect(helper.calculate_bar_height("50.0", 100)).to(eq(50.0))
      end
    end
  end

  describe "#currency_with_color" do
    context "with positive values" do
      it "uses positive color class by default" do
        result = helper.currency_with_color(100.0)
        expect(result).to(include("text-success-600"))
        expect(result).to(include("R$100.00"))
      end

      it "formats currency with 2 decimal places" do
        result = helper.currency_with_color(100.5)
        expect(result).to(include("R$100.50"))
      end

      it "handles zero value" do
        result = helper.currency_with_color(0)
        expect(result).to(include("text-success-600"))
        expect(result).to(include("R$0.00"))
      end

      it "handles custom positive color" do
        result = helper.currency_with_color(100.0, positive_color: "text-green-500")
        expect(result).to(include("text-green-500"))
        expect(result).not_to(include("text-success-600"))
      end
    end

    context "with negative values" do
      it "uses negative color class by default" do
        result = helper.currency_with_color(-100.0)
        expect(result).to(include("text-error-600"))
        expect(result).to(include("R$-100.00"))
      end

      it "formats negative currency correctly" do
        result = helper.currency_with_color(-50.75)
        expect(result).to(include("R$-50.75"))
      end

      it "handles custom negative color" do
        result = helper.currency_with_color(-100.0, negative_color: "text-red-500")
        expect(result).to(include("text-red-500"))
        expect(result).not_to(include("text-error-600"))
      end
    end

    context "with custom colors" do
      it "allows both colors to be customized" do
        result = helper.currency_with_color(100.0,
                                             positive_color: "text-blue-500",
                                             negative_color: "text-yellow-500")
        expect(result).to(include("text-blue-500"))
        expect(result).not_to(include("text-yellow-500"))
      end

      it "uses correct color based on value sign" do
        positive_result = helper.currency_with_color(50.0,
                                                     positive_color: "text-blue-500",
                                                     negative_color: "text-yellow-500")
        negative_result = helper.currency_with_color(-50.0,
                                                      positive_color: "text-blue-500",
                                                      negative_color: "text-yellow-500")

        expect(positive_result).to(include("text-blue-500"))
        expect(negative_result).to(include("text-yellow-500"))
      end
    end

    context "with edge cases" do
      it "handles very large numbers" do
        result = helper.currency_with_color(1_000_000.0)
        expect(result).to(include("R$1000000.00"))
      end

      it "handles very small numbers" do
        result = helper.currency_with_color(0.01)
        expect(result).to(include("R$0.01"))
      end

      it "wraps content in span tag" do
        result = helper.currency_with_color(100.0)
        expect(result).to(match(/<span[^>]*>.*<\/span>/))
      end
    end
  end
end

