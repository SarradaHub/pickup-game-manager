require "rails_helper"

RSpec.describe(Expense, type: :model) do
  fixtures :expenses

  describe "validations" do
    it "is valid with valid attributes (from fixtures)" do
      expect(expenses(:food)).to(be_valid)
      expect(expenses(:transportation)).to(be_valid)
      expect(expenses(:entertainment)).to(be_valid)
      expect(expenses(:utilities)).to(be_valid)
      expect(expenses(:equipment)).to(be_valid)
    end

    it "requires type" do
      expense = described_class.new(description: "Test expense", unit_value: 10.0, quantity: 1, date: Time.zone.today)
      expect(expense).not_to(be_valid)
      expect(expense.errors[:type]).to(include("can't be blank"))
    end

    it "requires description" do
      expense = described_class.new(type: "Basic", unit_value: 10.0, quantity: 1, date: Time.zone.today)
      expect(expense).not_to(be_valid)
      expect(expense.errors[:description]).to(include("can't be blank"))
    end

    it "requires unit_value" do
      expense = described_class.new(type: "Basic", description: "Test expense", quantity: 1, date: Time.zone.today)
      expect(expense).not_to(be_valid)
      expect(expense.errors[:unit_value]).to(include("can't be blank"))
    end

    it "requires quantity" do
      expense = described_class.new(type: "Basic", description: "Test expense", unit_value: 10.0, date: Time.zone.today)
      expect(expense).not_to(be_valid)
      expect(expense.errors[:quantity]).to(include("can't be blank"))
    end

    it "requires quantity to be greater than 0" do
      expense = described_class.new(type: "Basic", description: "Test expense", unit_value: 10.0, quantity: 0,
                                    date: Time.zone.today)
      expect(expense).not_to(be_valid)
      expect(expense.errors[:quantity]).to(include("must be greater than 0"))
    end

    it "requires date" do
      expense = described_class.new(type: "Basic", description: "Test expense", unit_value: 10.0, quantity: 1)
      expect(expense).not_to(be_valid)
      expect(expense.errors[:date]).to(include("can't be blank"))
    end
  end

  describe "attributes" do
    let(:expense) { expenses(:food) }

    it "has the correct type" do
      expect(expense.type).to(eq("Basic"))
    end

    it "has the correct description" do
      expect(expense.description).to(eq("Field"))
    end

    it "has the correct unit_value" do
      expect(expense.unit_value).to(eq(650.0))
    end

    it "has the correct quantity" do
      expect(expense.quantity).to(eq(1))
    end

    it "has the correct date" do
      expect(expense.date).to(eq(Date.parse("2025-08-15")))
    end
  end

  describe "fixtures" do
    it "loads all expense fixtures correctly" do
      expect(expenses(:food)).to(be_valid)
      expect(expenses(:transportation)).to(be_valid)
      expect(expenses(:entertainment)).to(be_valid)
      expect(expenses(:utilities)).to(be_valid)
      expect(expenses(:equipment)).to(be_valid)
    end

    it "has different expense types" do
      types = described_class.pluck(:type)
      expect(types).to(include("Basic", "Intermediary", "Advanced"))
    end

    it "has different expense amounts" do
      amounts = described_class.pluck(:unit_value)
      expect(amounts).to(include(650.0, 50.0, 350.0, 150.0))
    end

    it "has different quantities" do
      quantities = described_class.pluck(:quantity)
      expect(quantities).to(include(1, 2))
    end
  end

  describe "data types" do
    let(:expense) { expenses(:transportation) }

    it "stores type as string" do
      expect(expense.type).to(eq("Intermediary"))
    end

    it "stores description as string" do
      expect(expense.description).to(eq("Goalkeeper"))
    end

    it "stores unit_value as float" do
      expect(expense.unit_value).to(eq(50.0))
    end

    it "stores quantity as integer" do
      expect(expense.quantity).to(eq(2))
    end

    it "stores date as date" do
      expect(expense.date).to(eq(Date.parse("2025-08-20")))
    end
  end

  describe "total_value method" do
    it "calculates total value correctly for single quantity" do
      expense = expenses(:food)
      expect(expense.total_value).to(eq(650.0))
    end

    it "calculates total value correctly for multiple quantity" do
      expense = expenses(:transportation)
      expect(expense.total_value).to(eq(100.0)) # 50.0 * 2
    end

    it "updates total value when quantity changes" do
      expense = expenses(:food)
      expense.quantity = 3
      expect(expense.total_value).to(eq(1950.0)) # 650.0 * 3
    end

    it "updates total value when unit_value changes" do
      expense = expenses(:food)
      expense.unit_value = 100.0
      expect(expense.total_value).to(eq(100.0)) # 100.0 * 1
    end
  end

  describe "model behavior" do
    it "can create a new expense" do
      expense = described_class.new(
        type: "Basic",
        description: "New expense",
        unit_value: 100.0,
        quantity: 1,
        date: Time.zone.today,
      )

      expect(expense).to(be_valid)
      expect(expense.save).to(be(true))
      expect(described_class.count).to(eq(6))
    end

    it "can update an existing expense" do
      expense = expenses(:food)
      expense.description = "Updated description"
      expense.unit_value = 200.0

      expect(expense.save).to(be(true))
      expect(expense.reload.description).to(eq("Updated description"))
      expect(expense.reload.unit_value).to(eq(200.0))
    end

    it "can update quantity" do
      expense = expenses(:food)
      expense.quantity = 5

      expect(expense.save).to(be(true))
      expect(expense.reload.quantity).to(eq(5))
      expect(expense.total_value).to(eq(3250.0))
    end
  end
end
