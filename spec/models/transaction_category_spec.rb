require "rails_helper"

RSpec.describe(TransactionCategory, type: :model) do
  fixtures :transaction_categories, :incomes, :payments

  describe "validations" do
    it "is valid with valid attributes (from fixtures)" do
      expect(transaction_categories(:daily_transaction)).to(be_valid)
      expect(transaction_categories(:monthly_transaction)).to(be_valid)
    end

    it "requires name" do
      category = described_class.new(description: "Test description")
      expect(category).not_to(be_valid)
      expect(category.errors[:name]).to(include("can't be blank"))
    end

    it "enforces name uniqueness" do
      existing_category = transaction_categories(:daily_transaction)
      duplicate_category = described_class.new(name: existing_category.name, description: "Different description")
      expect(duplicate_category).not_to(be_valid)
      expect(duplicate_category.errors[:name]).to(include("has already been taken"))
    end

    it "does not require description" do
      category = described_class.new(name: "Test Category")
      expect(category).to(be_valid)
    end
  end

  describe "associations" do
    it "has many incomes" do
      category = transaction_categories(:daily_transaction)
      expect(category.incomes).to(include(incomes(:daily)))
    end

    it "has many payments" do
      category = transaction_categories(:daily_transaction)
      expect(category.payments).to(include(payments(:weekend_payment)))
    end

    it "can access income details through association" do
      category = transaction_categories(:daily_transaction)
      expect(category.incomes.first.unit_value).to(eq(15.0))
      expect(category.incomes.first.date).to(eq(Date.parse("2025-08-15")))
    end

    it "can access payment details through association" do
      category = transaction_categories(:daily_transaction)
      expect(category.payments.first.amount).to(eq(15.0))
      expect(category.payments.first.status).to(eq("paid"))
    end
  end

  describe "scopes" do
    it "can find categories by name" do
      daily_category = described_class.find_by(name: "daily")
      expect(daily_category).to(eq(transaction_categories(:daily_transaction)))
    end

    it "can find categories by description" do
      daily_category = described_class.find_by(description: "Daily game participation income")
      expect(daily_category).to(eq(transaction_categories(:daily_transaction)))
    end
  end

  describe "model behavior" do
    it "can create a new transaction category" do
      category = described_class.new(
        name: "Weekly",
        description: "Weekly subscription income",
      )

      expect(category).to(be_valid)
      expect(category.save).to(be(true))
      expect(described_class.count).to(eq(3))
    end

    it "can update an existing transaction category" do
      category = transaction_categories(:daily_transaction)
      category.description = "Updated daily description"

      expect(category.save).to(be(true))
      expect(category.reload.description).to(eq("Updated daily description"))
    end

    it "cannot delete a transaction category with associated records" do
      category = transaction_categories(:monthly_transaction)
      expect { category.destroy }.to(raise_error(ActiveRecord::InvalidForeignKey))
    end
  end

  describe "data integrity" do
    it "maintains referential integrity with incomes" do
      category = transaction_categories(:daily_transaction)
      income_count = category.incomes.count

      expect(income_count).to(be > 0)
      expect { category.destroy }.to(raise_error(ActiveRecord::InvalidForeignKey))
    end

    it "maintains referential integrity with payments" do
      category = transaction_categories(:daily_transaction)
      payment_count = category.payments.count

      expect(payment_count).to(be > 0)
      expect { category.destroy }.to(raise_error(ActiveRecord::InvalidForeignKey))
    end
  end

  describe "fixtures" do
    it "loads all transaction category fixtures correctly" do
      expect(transaction_categories(:daily_transaction)).to(be_valid)
      expect(transaction_categories(:monthly_transaction)).to(be_valid)
    end

    it "has different transaction category names" do
      names = described_class.pluck(:name)
      expect(names).to(include("daily", "monthly"))
    end

    it "has different transaction category descriptions" do
      descriptions = described_class.pluck(:description)
      expect(descriptions).to(include("Daily game participation income", "Monthly subscription income"))
    end
  end
end
