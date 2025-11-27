require "rails_helper"

RSpec.describe(ExpensesController, type: :controller) do
  fixtures :expenses, :incomes, :matches

  # Enable view rendering for JSON responses
  render_views

  let(:valid_attributes) do
    { type: "Basic", description: "Test expense", unit_value: 100.0, quantity: 1, date: Time.zone.today }
  end

  let(:invalid_attributes) do
    { type: "", description: "", unit_value: nil, quantity: nil, date: nil }
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
      expense = expenses(:food)
      get :show, params: { id: expense.to_param }, session: valid_session
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
      expense = expenses(:food)
      get :edit, params: { id: expense.to_param }, session: valid_session
      expect(response).to(be_successful)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Expense" do
        expect do
          post(:create, params: { expense: valid_attributes }, session: valid_session)
        end.to(change(Expense, :count).by(1))
      end

      it "redirects to the created expense" do
        post :create, params: { expense: valid_attributes }, session: valid_session
        expect(response).to(redirect_to(Expense.last))
      end

      it "responds with JSON format" do
        post :create, params: { expense: valid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:created))
        expect(response.body).not_to(be_empty)
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("id"))
      end
    end

    context "with invalid params" do
      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post :create, params: { expense: invalid_attributes }, session: valid_session
        expect(response).to(have_http_status(:unprocessable_content))
      end

      it "responds with JSON format and errors" do
        post :create, params: { expense: invalid_attributes, format: :json }, session: valid_session
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
        { type: "Intermediary", description: "Updated expense", unit_value: 200.0, quantity: 2,
          date: Time.zone.today - 1 }
      end

      it "updates the requested expense" do
        expense = expenses(:food)
        put :update, params: { id: expense.to_param, expense: new_attributes }, session: valid_session
        expense.reload
        expect(expense.type).to(eq("Intermediary"))
        expect(expense.description).to(eq("Updated expense"))
        expect(expense.unit_value).to(eq(200.0))
        expect(expense.quantity).to(eq(2))
        expect(expense.date).to(eq(Time.zone.today - 1))
      end

      it "redirects to the expense" do
        expense = expenses(:food)
        put :update, params: { id: expense.to_param, expense: new_attributes }, session: valid_session
        expect(response).to(have_http_status(:see_other))
        expect(response).to(redirect_to(expense))
      end

      it "responds with JSON format" do
        expense = expenses(:food)
        put :update, params: { id: expense.to_param, expense: new_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:ok))
        expect(response.body).not_to(be_empty)
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("id"))
      end
    end

    context "with invalid params" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        expense = expenses(:food)
        put :update, params: { id: expense.to_param, expense: invalid_attributes }, session: valid_session
        expect(response).to(have_http_status(:unprocessable_content))
      end

      it "responds with JSON format and errors" do
        expense = expenses(:food)
        put :update, params: { id: expense.to_param, expense: invalid_attributes, format: :json },
                     session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:unprocessable_content))
        parsed_response = response.parsed_body
        expect(parsed_response).to(be_a(Hash))
        expect(parsed_response).not_to(be_empty)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested expense" do
      expense = expenses(:food)
      expect do
        delete(:destroy, params: { id: expense.to_param }, session: valid_session)
      end.to(change(Expense, :count).by(-1))
    end

    it "redirects to the expenses list" do
      expense = expenses(:food)
      delete :destroy, params: { id: expense.to_param }, session: valid_session
      expect(response).to(have_http_status(:see_other))
      expect(response).to(redirect_to(expenses_path))
    end

    it "responds with JSON format" do
      expense = expenses(:food)
      delete :destroy, params: { id: expense.to_param, format: :json }, session: valid_session
      expect(response).to(have_http_status(:no_content))
    end
  end
end
