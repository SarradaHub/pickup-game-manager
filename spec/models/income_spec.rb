require 'rails_helper'

RSpec.describe Income, type: :model do
  fixtures :incomes, :transaction_categories

  describe 'validations' do
    it 'is valid with valid attributes (from fixtures)' do
      expect(incomes(:daily)).to be_valid
      expect(incomes(:monthly)).to be_valid
    end

    it 'requires transaction_category' do
      income = Income.new(unit_value: 100.0, date: Date.today)
      expect(income).not_to be_valid
      expect(income.errors[:transaction_category]).to include("must exist")
    end

    it 'requires unit_value' do
      income = Income.new(transaction_category: transaction_categories(:daily_transaction), date: Date.today)
      expect(income).not_to be_valid
      expect(income.errors[:unit_value]).to include("can't be blank")
    end

    it 'requires date' do
      income = Income.new(transaction_category: transaction_categories(:daily_transaction), unit_value: 100.0)
      expect(income).not_to be_valid
      expect(income.errors[:date]).to include("can't be blank")
    end
  end

  describe 'attributes' do
    let(:income) { incomes(:daily) }

    it 'has the correct transaction_category' do
      expect(income.transaction_category).to eq(transaction_categories(:daily_transaction))
    end

    it 'has the correct unit_value' do
      expect(income.unit_value).to eq(15.0)
    end

    it 'has the correct date' do
      expect(income.date).to eq(Date.parse('2025-08-15'))
    end
  end

  describe 'fixtures' do
    it 'loads all income fixtures correctly' do
      expect(incomes(:daily)).to be_valid
      expect(incomes(:monthly)).to be_valid
    end

    it 'has different transaction categories' do
      categories = Income.joins(:transaction_category).pluck('transaction_categories.name')
      expect(categories).to include('daily', 'monthly')
    end

    it 'has different income amounts' do
      amounts = Income.pluck(:unit_value)
      expect(amounts).to include(15.0, 35.0)
    end
  end

  describe 'data types' do
    let(:income) { incomes(:monthly) }

    it 'stores transaction_category as association' do
      expect(income.transaction_category.name).to eq('monthly')
    end

    it 'stores unit_value as float' do
      expect(income.unit_value).to eq(35.0)
    end

    it 'stores date as date' do
      expect(income.date).to eq(Date.parse('2025-08-20'))
    end
  end

  describe 'model behavior' do
    it 'can create a new income' do
      income = Income.new(
        transaction_category: transaction_categories(:daily_transaction),
        unit_value: 20.0,
        date: Date.today
      )

      expect(income).to be_valid
      expect(income.save).to be true
      expect(Income.count).to eq(3)
    end

    it 'can update an existing income' do
      income = incomes(:daily)
      income.unit_value = 25.0

      expect(income.save).to be true
      expect(income.reload.unit_value).to eq(25.0)
    end
  end

  describe 'type method' do
    it 'returns the transaction category name' do
      income = incomes(:daily)
      expect(income.type).to eq('daily')
    end

    it 'returns nil when transaction_category is nil' do
      income = Income.new(unit_value: 100.0, date: Date.today)
      expect(income.type).to be_nil
    end

    it 'returns the correct type for monthly income' do
      income = incomes(:monthly)
      expect(income.type).to eq('monthly')
    end
  end

  describe 'type= method' do
    it 'sets transaction_category by name' do
      income = Income.new(unit_value: 100.0, date: Date.today)
      income.type = 'daily'

      expect(income.transaction_category).to eq(transaction_categories(:daily_transaction))
    end

    it 'updates transaction_category when type is changed' do
      income = incomes(:daily)
      income.type = 'monthly'

      expect(income.transaction_category).to eq(transaction_categories(:monthly_transaction))
    end

    it 'sets transaction_category to nil when type does not exist' do
      income = Income.new(unit_value: 100.0, date: Date.today)
      income.type = 'non_existent_type'

      expect(income.transaction_category).to be_nil
    end
  end
end
