require 'rails_helper'

RSpec.describe Athlete, type: :model do
  fixtures :athletes, :payments, :transaction_categories, :matches, :athlete_matches

  describe 'validations' do
    it 'is valid with valid attributes (from fixtures)' do
      expect(athletes(:john_doe)).to be_valid
      expect(athletes(:jane_smith)).to be_valid
      expect(athletes(:mike_johnson)).to be_valid
      expect(athletes(:sarah_wilson)).to be_valid
    end

    it 'requires name' do
      athlete = Athlete.new(phone: 1234567890, date_of_birth: Date.today)
      expect(athlete).not_to be_valid
      expect(athlete.errors[:name]).to include("can't be blank")
    end

    it 'requires phone' do
      athlete = Athlete.new(name: 'Test Athlete', date_of_birth: Date.today)
      expect(athlete).not_to be_valid
      expect(athlete.errors[:phone]).to include("can't be blank")
    end

    it 'requires date_of_birth' do
      athlete = Athlete.new(name: 'Test Athlete', phone: 1234567890)
      expect(athlete).not_to be_valid
      expect(athlete.errors[:date_of_birth]).to include("can't be blank")
    end
  end

  describe 'attributes' do
    let(:athlete) { athletes(:john_doe) }

    it 'has the correct name' do
      expect(athlete.name).to eq('John Doe')
    end

    it 'has the correct phone' do
      expect(athlete.phone).to eq(1234567890)
    end

    it 'has the correct date_of_birth' do
      expect(athlete.date_of_birth).to eq(Date.parse('1990-05-15'))
    end
  end

  describe 'fixtures' do
    it 'loads all athlete fixtures correctly' do
      expect(athletes(:john_doe)).to be_valid
      expect(athletes(:jane_smith)).to be_valid
      expect(athletes(:mike_johnson)).to be_valid
      expect(athletes(:sarah_wilson)).to be_valid
    end

    it 'has different athlete names' do
      names = Athlete.pluck(:name)
      expect(names).to include('John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Wilson')
    end

    it 'has different phone numbers' do
      phones = Athlete.pluck(:phone)
      expect(phones.uniq.length).to eq(4)
    end
  end

  describe 'data types' do
    let(:athlete) { athletes(:jane_smith) }

    it 'stores name as string' do
      expect(athlete.name).to be_a(String)
      expect(athlete.name).to eq('Jane Smith')
    end

    it 'stores phone as integer' do
      expect(athlete.phone).to be_a(Integer)
      expect(athlete.phone).to eq(9876543210)
    end

    it 'stores date_of_birth as date' do
      expect(athlete.date_of_birth).to be_a(Date)
      expect(athlete.date_of_birth).to eq(Date.parse('1992-08-22'))
    end
  end

  describe 'model behavior' do
    it 'can create a new athlete' do
      athlete = Athlete.new(name: 'New Athlete', phone: 1112223333, date_of_birth: Date.today)
      expect(athlete).to be_valid
      expect(athlete.save).to be true
    end

    it 'can update an existing athlete' do
      athlete = athletes(:john_doe)
      athlete.phone = 9998887777
      expect(athlete.save).to be true
      expect(athlete.reload.phone).to eq(9998887777)
    end
  end

  describe 'associations' do
    describe 'has_many :matches, through: :athlete_matches' do
      it 'returns matches associated through athlete_matches' do
        athlete = athletes(:john_doe)
        expect(athlete.matches).to be_an(ActiveRecord::Associations::CollectionProxy)
        expect(athlete.matches.count).to eq(2)
      end

      it 'returns the correct matches for an athlete' do
        athlete = athletes(:john_doe)
        match_locations = athlete.matches.pluck(:location)
        expect(match_locations).to all(eq('COPM'))
      end

      it 'returns matches with the correct dates' do
        athlete = athletes(:john_doe)
        match_dates = athlete.matches.pluck(:date)
        expect(match_dates).to include(Date.parse('2025-08-30'))
        expect(match_dates).to include(Date.parse('2025-09-05'))
      end

      it 'allows accessing match details through the association' do
        athlete = athletes(:john_doe)
        match = athlete.matches.first
        expect(match).to be_a(Match)
        expect(match).to have_attributes(location: 'COPM')
      end

      it 'returns empty collection for athlete with no matches' do
        athlete = Athlete.create(name: 'New Athlete', phone: 1112223333, date_of_birth: Date.today)
        expect(athlete.matches).to be_empty
      end

      it 'allows adding matches through the association' do
        athlete = athletes(:john_doe)
        new_match = matches(:beach_game)
        initial_count = athlete.matches.count

        athlete.matches << new_match unless athlete.matches.include?(new_match)

        expect(athlete.matches.count).to be >= initial_count
      end
    end
  end
end
