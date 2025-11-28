require "rails_helper"

RSpec.describe(IncomesController, type: :controller) do
  fixtures :transaction_categories, :incomes, :expenses, :matches

  # Enable view rendering for JSON responses
  render_views

  let(:valid_attributes) do
    {
      unit_value: 20.0,
      date: Time.zone.today,
      transaction_category_id: transaction_categories(:daily_transaction).id,
    }
  end

  let(:invalid_attributes) do
    { unit_value: nil, date: nil, transaction_category_id: nil }
  end

  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: {}, session: valid_session
      expect(response).to(be_successful)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      income = Income.create!(valid_attributes)
      get :show, params: { id: income.to_param }, session: valid_session
      expect(response).to(be_successful)
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}, session: valid_session
      expect(response).to(be_successful)
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      income = Income.create!(valid_attributes)
      get :edit, params: { id: income.to_param }, session: valid_session
      expect(response).to(be_successful)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Income" do
        expect do
          post(:create, params: { income: valid_attributes }, session: valid_session)
        end.to(change(Income, :count).by(1))
      end

      it "redirects to the created income" do
        post :create, params: { income: valid_attributes }, session: valid_session
        expect(response).to(redirect_to(Income.last))
      end

      it "responds with JSON format" do
        post :create, params: { income: valid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:created))
        expect(response.body).not_to(be_empty)
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("id"))
      end
    end

    context "with invalid params" do
      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post :create, params: { income: invalid_attributes }, session: valid_session
        expect(response).to(have_http_status(:unprocessable_content))
      end

      it "responds with JSON format and errors" do
        post :create, params: { income: invalid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:unprocessable_content))
        parsed_response = response.parsed_body
        expect(parsed_response).to(be_a(Hash))
        expect(parsed_response).not_to(be_empty)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) do
        { unit_value: 50.0, date: Time.zone.today - 1 }
      end

      it "updates the requested income" do
        income = Income.create!(valid_attributes)
        put :update, params: { id: income.to_param, income: new_attributes }, session: valid_session
        income.reload
        expect(income.unit_value).to(eq(50.0))
        expect(income.date).to(eq(Time.zone.today - 1))
      end

      it "redirects to the income" do
        income = Income.create!(valid_attributes)
        put :update, params: { id: income.to_param, income: new_attributes }, session: valid_session
        expect(response).to(have_http_status(:see_other))
        expect(response).to(redirect_to(income))
      end

      it "responds with JSON format" do
        income = Income.create!(valid_attributes)
        put :update, params: { id: income.to_param, income: new_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:ok))
        expect(response.body).not_to(be_empty)
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("id"))
      end
    end

    context "with invalid params" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        income = Income.create!(valid_attributes)
        put :update, params: { id: income.to_param, income: invalid_attributes }, session: valid_session
        expect(response).to(have_http_status(:unprocessable_content))
      end

      it "responds with JSON format and errors" do
        income = Income.create!(valid_attributes)
        put :update, params: { id: income.to_param, income: invalid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:unprocessable_content))
        parsed_response = response.parsed_body
        expect(parsed_response).to(be_a(Hash))
        expect(parsed_response).not_to(be_empty)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested income" do
      income = Income.create!(valid_attributes)
      expect do
        delete(:destroy, params: { id: income.to_param }, session: valid_session)
      end.to(change(Income, :count).by(-1))
    end

    it "redirects to the incomes list" do
      income = Income.create!(valid_attributes)
      delete :destroy, params: { id: income.to_param }, session: valid_session
      expect(response).to(have_http_status(:see_other))
      expect(response).to(redirect_to(incomes_path))
    end

    it "responds with JSON format" do
      income = Income.create!(valid_attributes)
      delete :destroy, params: { id: income.to_param, format: :json }, session: valid_session
      expect(response).to(have_http_status(:no_content))
    end
  end
end
