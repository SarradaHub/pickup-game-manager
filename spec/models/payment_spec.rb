require 'rails_helper'

RSpec.describe Payment, type: :model do
  fixtures :payments, :athletes, :matches, :transaction_categories

  describe 'associations' do
    it 'belongs to an athlete' do
      payment = payments(:weekend_payment)
      expect(payment.athlete).to be_an(Athlete)
      expect(payment.athlete.name).to eq('John Doe')
    end

    it 'belongs to a match' do
      payment = payments(:weekend_payment)
      expect(payment.match).to be_a(Match)
      expect(payment.match.location).to eq('COPM')
    end
  end

  describe 'attributes' do
    let(:payment) { payments(:weekend_payment) }

    it 'has the correct date' do
      expect(payment.date).to eq(Date.parse('2025-08-30'))
    end

    it 'has the correct status' do
      expect(payment.status).to eq('paid')
    end

    it 'has the correct description' do
      expect(payment.description).to eq('First week game payment')
    end

    it 'has the correct amount' do
      expect(payment.amount).to eq(15.0)
    end
  end

  describe 'fixtures' do
    it 'loads all payment fixtures correctly' do
      expect(payments(:weekend_payment)).to be_valid
      expect(payments(:indoor_payment)).to be_valid
      expect(payments(:beach_payment)).to be_valid
      expect(payments(:night_payment)).to be_valid
    end

    it 'has different payment statuses' do
      statuses = Payment.pluck(:status)
      expect(statuses).to include('paid', 'pending')
    end

    it 'has different payment amounts' do
      amounts = Payment.pluck(:amount)
      expect(amounts).to include(15.0)
    end

    it 'has different payment dates' do
      dates = Payment.pluck(:date)
      expect(dates.uniq.length).to eq(4)
    end
  end

  describe 'data types' do
    let(:payment) { payments(:indoor_payment) }

    it 'stores date as date' do
      expect(payment.date).to be_a(Date)
    end

    it 'stores status as string' do
      expect(payment.status).to eq('paid')
    end

    it 'stores description as string' do
      expect(payment.description).to eq('Monthly subscription payment')
    end

    it 'stores amount as float' do
      expect(payment.amount).to eq(35.0)
    end
  end

  describe 'model behavior' do
    it 'can create a new payment' do
      athlete = athletes(:john_doe)
      match = matches(:weekend_game)
      transaction_category = transaction_categories(:daily_transaction)

      payment = Payment.new(
        date: Date.today,
        status: 'pending',
        athlete: athlete,
        match: match,
        transaction_category: transaction_category,
        description: 'New payment',
        amount: 20.0
      )

      expect(payment).to be_valid
      expect(payment.save).to be true
      expect(Payment.count).to eq(5)
    end

    it 'can update an existing payment' do
      payment = payments(:weekend_payment)
      payment.status = 'pending'
      payment.amount = 25.0

      expect(payment.save).to be true
      expect(payment.reload.status).to eq('pending')
      expect(payment.reload.amount).to eq(25.0)
    end
  end

  describe 'relationships' do
    it 'can access athlete details through payment' do
      payment = payments(:weekend_payment)
      expect(payment.athlete.name).to eq('John Doe')
      expect(payment.athlete.phone).to eq(1234567890)
    end

    it 'can access match details through payment' do
      payment = payments(:weekend_payment)
      expect(payment.match.date).to eq(Date.parse('2025-08-30'))
      expect(payment.match.location).to eq('COPM')
    end

    it 'can find payments by athlete' do
      john_payments = Payment.joins(:athlete).where(athletes: { name: 'John Doe' })
      expect(john_payments.count).to eq(1)
    end

    it 'can find payments by match' do
      weekend_payments = Payment.joins(:match).where(matches: { date: Date.parse('2025-08-30') })
      expect(weekend_payments.count).to eq(1)
    end
  end

  describe 'modality method' do
    it 'returns the transaction category name' do
      payment = payments(:weekend_payment)
      expect(payment.modality).to eq('daily')
    end

    it 'returns nil when transaction_category is nil' do
      payment = Payment.new(amount: 100.0, status: 'paid', date: Date.today)
      expect(payment.modality).to be_nil
    end

    it 'returns the correct modality for monthly payment' do
      payment = payments(:indoor_payment)
      expect(payment.modality).to eq('monthly')
    end
  end

  describe 'modality= method' do
    it 'sets transaction_category by name' do
      payment = Payment.new(amount: 100.0, status: 'paid', date: Date.today, athlete: athletes(:john_doe), match: matches(:weekend_game))
      payment.modality = 'daily'

      expect(payment.transaction_category).to eq(transaction_categories(:daily_transaction))
    end

    it 'updates transaction_category when modality is changed' do
      payment = payments(:weekend_payment)
      payment.modality = 'monthly'

      expect(payment.transaction_category).to eq(transaction_categories(:monthly_transaction))
    end

    it 'sets transaction_category to nil when modality does not exist' do
      payment = Payment.new(amount: 100.0, status: 'paid', date: Date.today, athlete: athletes(:john_doe), match: matches(:weekend_game))
      payment.modality = 'non_existent_modality'

      expect(payment.transaction_category).to be_nil
    end
  end

  describe 'scopes' do
    describe '.pending' do
      it 'returns only pending payments' do
        pending_payments = Payment.pending
        expect(pending_payments).to all(have_attributes(status: 'pending'))
        expect(pending_payments.count).to eq(1)
        expect(pending_payments).to include(payments(:beach_payment))
      end

      it 'excludes paid payments' do
        pending_payments = Payment.pending
        expect(pending_payments).not_to include(payments(:weekend_payment))
        expect(pending_payments).not_to include(payments(:indoor_payment))
        expect(pending_payments).not_to include(payments(:night_payment))
      end
    end

    describe '.paid' do
      it 'returns only paid payments' do
        paid_payments = Payment.paid
        expect(paid_payments).to all(have_attributes(status: 'paid'))
        expect(paid_payments.count).to eq(3)
        expect(paid_payments).to include(payments(:weekend_payment))
        expect(paid_payments).to include(payments(:indoor_payment))
        expect(paid_payments).to include(payments(:night_payment))
      end

      it 'excludes pending payments' do
        paid_payments = Payment.paid
        expect(paid_payments).not_to include(payments(:beach_payment))
      end
    end
  end
end
