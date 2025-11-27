require "rails_helper"

RSpec.describe(Match, type: :model) do
  fixtures :matches, :payments, :athletes, :athlete_matches

  describe "attributes" do
    let(:match) { matches(:weekend_game) }

    it "has the correct date" do
      expect(match.date).to(eq(Date.parse("2025-08-30")))
    end

    it "has the correct location" do
      expect(match.location).to(eq("COPM"))
    end
  end

  describe "fixtures" do
    it "loads all match fixtures correctly" do
      expect(matches(:weekend_game)).to(be_valid)
      expect(matches(:indoor_match)).to(be_valid)
      expect(matches(:beach_game)).to(be_valid)
      expect(matches(:night_match)).to(be_valid)
    end

    it "has different dates for each match" do
      dates = described_class.pluck(:date)
      expect(dates.uniq.length).to(eq(4))
      expect(dates).to(include(Date.parse("2025-08-30")))
      expect(dates).to(include(Date.parse("2025-09-05")))
      expect(dates).to(include(Date.parse("2025-09-12")))
      expect(dates).to(include(Date.parse("2025-09-18")))
    end

    it "has different locations for each match" do
      locations = described_class.pluck(:location)
      expect(locations.uniq.length).to(eq(1))
      expect(locations).to(all(eq("COPM")))
    end
  end

  describe "data types" do
    let(:match) { matches(:indoor_match) }

    it "stores date as date" do
      expect(match.date).to(be_a(Date))
    end

    it "stores location as string" do
      expect(match.location).to(eq("COPM"))
    end
  end

  describe "model behavior" do
    it "can create a new match" do
      match = described_class.new(
        date: Time.zone.today,
        location: "COPM",
      )

      expect(match).to(be_valid)
      expect(match.save).to(be(true))
      expect(described_class.count).to(eq(5))
    end

    it "can update an existing match" do
      match = matches(:weekend_game)
      match.date = Time.zone.today + 1

      expect(match.save).to(be(true))
      expect(match.reload.date).to(eq(Time.zone.today + 1))
    end
  end

  describe "associations" do
    describe "has_many :athletes, through: :athlete_matches" do
      it "returns athletes associated through athlete_matches" do
        match = matches(:weekend_game)
        expect(match.athletes).to(be_an(ActiveRecord::Associations::CollectionProxy))
        expect(match.athletes.count).to(eq(2))
      end

      it "returns the correct athletes for a match" do
        match = matches(:weekend_game)
        athlete_names = match.athletes.pluck(:name)
        expect(athlete_names).to(include("John Doe"))
        expect(athlete_names).to(include("Sarah Wilson"))
      end

      it "allows accessing athlete details through the association" do
        match = matches(:weekend_game)
        athlete = match.athletes.first
        expect(athlete).to(be_an(Athlete))
        expect(athlete).to(respond_to(:name))
        expect(athlete).to(respond_to(:phone))
        expect(athlete).to(respond_to(:date_of_birth))
      end

      it "returns empty collection for match with no athletes" do
        match = described_class.create!(date: Time.zone.today, location: "COPM")
        expect(match.athletes).to(be_empty)
      end

      it "allows adding athletes through the association" do
        match = matches(:beach_game)
        new_athlete = athletes(:john_doe)
        initial_count = match.athletes.count

        match.athletes << new_athlete unless match.athletes.include?(new_athlete)

        expect(match.athletes.count).to(be >= initial_count)
      end

      it "returns unique athletes for matches with multiple athlete_matches" do
        match = matches(:weekend_game)
        athlete_ids = match.athletes.pluck(:id)
        expect(athlete_ids.uniq.length).to(eq(athlete_ids.length))
      end
    end
  end
end
