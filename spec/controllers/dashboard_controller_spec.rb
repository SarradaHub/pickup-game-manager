require "rails_helper"

RSpec.describe(DashboardController, type: :controller) do
  fixtures :transaction_categories, :athletes, :matches, :payments, :expenses, :incomes

  let(:valid_session) { {} }

  # Enable view rendering for controller specs to ensure instance variables are set
  render_views

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: {}, session: valid_session
      expect(response).to(be_successful)
    end

    it "loads quick stats" do
      get :index, params: {}, session: valid_session
      expect(assigns(:total_athletes)).to(be_a(Integer))
      expect(assigns(:total_athletes)).to(be >= 0)
      expect(assigns(:total_matches)).to(be_a(Integer))
      expect(assigns(:total_matches)).to(be >= 0)
      expect(assigns(:pending_payments)).to(be_a(Integer))
      expect(assigns(:pending_payments)).to(be >= 0)
      expect(assigns(:upcoming_matches)).to(be_a(ActiveRecord::Relation))
    end

    it "loads recent activity" do
      get :index, params: {}, session: valid_session
      expect(assigns(:recent_payments)).to(be_a(ActiveRecord::Relation))
      expect(assigns(:recent_expenses)).to(be_a(ActiveRecord::Relation))
      expect(assigns(:recent_athletes)).to(be_a(ActiveRecord::Relation))
    end

    it "loads monthly summary" do
      get :index, params: {}, session: valid_session
      expect(assigns(:monthly_summary)).to(be_a(Hash))
      expect(assigns(:monthly_summary)).to(have_key(:income))
      expect(assigns(:monthly_summary)).to(have_key(:income_value))
      expect(assigns(:monthly_summary)).to(have_key(:expenses))
      expect(assigns(:monthly_summary)).to(have_key(:expenses_value))
      expect(assigns(:monthly_summary)).to(have_key(:profit))
    end

    it "loads yearly summary" do
      get :index, params: {}, session: valid_session
      expect(assigns(:yearly_summary)).to(be_a(Hash))
      expect(assigns(:yearly_summary)).to(have_key(:income))
      expect(assigns(:yearly_summary)).to(have_key(:income_value))
      expect(assigns(:yearly_summary)).to(have_key(:expenses))
      expect(assigns(:yearly_summary)).to(have_key(:expenses_value))
      expect(assigns(:yearly_summary)).to(have_key(:profit))
    end

    it "loads debtors" do
      get :index, params: {}, session: valid_session
      expect(assigns(:debtors)).to(be_a(ActiveRecord::Relation))
    end

    it "loads equilibrium point" do
      get :index, params: {}, session: valid_session
      expect(assigns(:equilibrium_point)).to(be_a(Hash))
      expect(assigns(:income_types)).to(be_an(Array))
      expect(assigns(:expenses_types)).to(be_an(Array))
    end

    it "limits upcoming matches to 5" do
      get :index, params: {}, session: valid_session
      expect(assigns(:upcoming_matches).count).to(be <= 5)
    end

    it "limits recent payments to 5" do
      get :index, params: {}, session: valid_session
      expect(assigns(:recent_payments).count).to(be <= 5)
    end

    it "limits recent expenses to 5" do
      get :index, params: {}, session: valid_session
      expect(assigns(:recent_expenses).count).to(be <= 5)
    end

    it "limits recent athletes to 5" do
      get :index, params: {}, session: valid_session
      expect(assigns(:recent_athletes).count).to(be <= 5)
    end
  end

  describe "equilibrium_point functionality through index" do
    it "sets default empty arrays for income_types and expenses_types when no params" do
      get :index, params: {}, session: valid_session
      expect(assigns(:income_types)).to(eq([]))
      expect(assigns(:expenses_types)).to(eq([]))
    end

    it "sets income_types from params" do
      get :index, params: { income_types: ["daily", "monthly"] }, session: valid_session
      expect(assigns(:income_types)).to(eq(["daily", "monthly"]))
    end

    it "sets expenses_types from params" do
      get :index, params: { expenses_types: ["Basic", "Intermediary"] }, session: valid_session
      expect(assigns(:expenses_types)).to(eq(["Basic", "Intermediary"]))
    end

    it "calculates equilibrium point with details" do
      get :index, params: {}, session: valid_session
      expect(assigns(:equilibrium_point)).to(be_a(Hash))
      expect(assigns(:equilibrium_point)).to(have_key(:equilibrium_point))
      expect(assigns(:equilibrium_point)).to(have_key(:income_total))
      expect(assigns(:equilibrium_point)).to(have_key(:expenses_total))
      expect(assigns(:equilibrium_point)).to(have_key(:income_unit_values))
      expect(assigns(:equilibrium_point)).to(have_key(:expenses_unit_values))
      expect(assigns(:equilibrium_point)).to(have_key(:income_count))
      expect(assigns(:equilibrium_point)).to(have_key(:expenses_count))
    end

    it "sets available income types" do
      get :index, params: {}, session: valid_session
      expect(assigns(:available_income_types)).to(be_an(Array))
      expect(assigns(:available_income_types)).to(all(be_a(String)))
    end

    it "sets available expense types" do
      get :index, params: {}, session: valid_session
      expect(assigns(:available_expense_types)).to(be_an(Array))
    end

    context "with specific income and expense types" do
      it "calculates equilibrium point with provided types" do
        get :index, params: { income_types: ["daily"], expenses_types: ["Basic"] }, session: valid_session
        expect(assigns(:income_types)).to(eq(["daily"]))
        expect(assigns(:expenses_types)).to(eq(["Basic"]))
        expect(assigns(:equilibrium_point)).to(be_a(Hash))
      end
    end
  end
end
