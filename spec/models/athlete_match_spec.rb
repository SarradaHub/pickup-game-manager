require "rails_helper"

RSpec.describe(AthleteMatch, type: :model) do
  fixtures :athlete_matches, :athletes, :matches

  describe "associations" do
    it "belongs to an athlete" do
      athlete_match = athlete_matches(:john_weekend)
      expect(athlete_match.athlete).to(be_an(Athlete))
      expect(athlete_match.athlete.name).to(eq("John Doe"))
    end

    it "belongs to a match" do
      athlete_match = athlete_matches(:john_weekend)
      expect(athlete_match.match).to(be_a(Match))
      expect(athlete_match.match.location).to(eq("COPM"))
    end
  end

  describe "fixtures" do
    it "loads all athlete_match fixtures correctly" do
      expect(athlete_matches(:john_weekend)).to(be_valid)
      expect(athlete_matches(:jane_indoor)).to(be_valid)
      expect(athlete_matches(:mike_beach)).to(be_valid)
      expect(athlete_matches(:sarah_night)).to(be_valid)
    end

    it "has the correct number of athlete_matches" do
      expect(described_class.count).to(eq(8))
    end

    it "has unique athlete-match combinations" do
      combinations = described_class.pluck(:athlete_id, :match_id)
      expect(combinations.uniq.length).to(eq(8))
    end
  end

  describe "relationships" do
    it "can access athlete details through athlete_match" do
      athlete_match = athlete_matches(:john_weekend)
      expect(athlete_match.athlete.name).to(eq("John Doe"))
      expect(athlete_match.athlete.phone).to(eq(1_234_567_890))
    end

    it "can access match details through athlete_match" do
      athlete_match = athlete_matches(:john_weekend)
      expect(athlete_match.match.date).to(eq(Date.parse("2025-08-30")))
      expect(athlete_match.match.location).to(eq("COPM"))
    end

    it "can find athlete_matches by athlete" do
      john_participations = described_class.joins(:athlete).where(athletes: { name: "John Doe" })
      expect(john_participations.count).to(eq(2))
    end

    it "can find athlete_matches by match" do
      weekend_participations = described_class.joins(:match).where(matches: { date: Date.parse("2025-08-30") })
      expect(weekend_participations.count).to(eq(2))
    end
  end

  describe "model behavior" do
    it "can create a new athlete_match" do
      athlete = athletes(:john_doe)
      match = matches(:beach_game)

      athlete_match = described_class.new(
        athlete: athlete,
        match: match,
      )

      expect(athlete_match).to(be_valid)
      expect(athlete_match.save).to(be(true))
      expect(described_class.count).to(eq(9))
    end

    it "can update an existing athlete_match" do
      athlete_match = athlete_matches(:john_weekend)
      new_match = matches(:beach_game)
      athlete_match.match = new_match

      expect(athlete_match.save).to(be(true))
      expect(athlete_match.reload.match.date).to(eq(Date.parse("2025-09-12")))
    end

    it "can delete an athlete_match" do
      athlete_match = athlete_matches(:sarah_weekend)
      expect { athlete_match.destroy }.to(change(described_class, :count).by(-1))
    end
  end

  describe "data integrity" do
    it "prevents duplicate athlete-match combinations" do
      athlete = athletes(:mike_johnson)
      match = matches(:weekend_game)

      # First one should be valid
      first = described_class.new(athlete: athlete, match: match)
      expect(first).to(be_valid)
      expect(first.save).to(be(true))

      # Second one with same combination should be invalid
      second = described_class.new(athlete: athlete, match: match)
      expect(second).not_to(be_valid)
      expect(second.errors[:athlete_id]).to(include("has already been taken"))
    end

    it "requires both athlete and match" do
      athlete_match = described_class.new
      expect(athlete_match).not_to(be_valid)
      expect(athlete_match.errors[:athlete]).to(include("must exist"))
      expect(athlete_match.errors[:match]).to(include("must exist"))
    end
  end

  describe "participation scenarios" do
    it "shows athletes participating in multiple matches" do
      john_participations = described_class.joins(:athlete).where(athletes: { name: "John Doe" })
      expect(john_participations.count).to(eq(2))
      expect(john_participations.map(&:match).map(&:location)).to(all(eq("COPM")))
    end

    it "shows matches with multiple athletes" do
      weekend_participations = described_class.joins(:match).where(matches: { date: Date.parse("2025-08-30") })
      expect(weekend_participations.count).to(eq(2))
      expect(weekend_participations.map(&:athlete).map(&:name)).to(include("John Doe", "Sarah Wilson"))
    end
  end
end
