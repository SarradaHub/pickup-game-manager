require "rails_helper"

RSpec.describe(MatchesController, type: :controller) do
  fixtures :matches, :payments, :athletes

  # Enable view rendering for JSON responses
  render_views

  let(:valid_attributes) do
    { date: Time.zone.today, location: "COPM" }
  end

  let(:invalid_attributes) do
    { date: nil, location: "" }
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
      match = matches(:weekend_game)
      get :show, params: { id: match.to_param }, session: valid_session
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
      match = matches(:weekend_game)
      get :edit, params: { id: match.to_param }, session: valid_session
      expect(response).to(be_successful)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Match" do
        expect do
          post(:create, params: { match: valid_attributes }, session: valid_session)
        end.to(change(Match, :count).by(1))
      end

      it "redirects to the created match" do
        post :create, params: { match: valid_attributes }, session: valid_session
        expect(response).to(redirect_to(Match.last))
      end

      it "responds with JSON format" do
        post :create, params: { match: valid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:created))
        expect(response.body).not_to(be_empty)
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("id"))
      end
    end

    context "with invalid params" do
      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post :create, params: { match: invalid_attributes }, session: valid_session
        expect(response).to(have_http_status(:unprocessable_content))
      end

      it "responds with JSON format and errors" do
        post :create, params: { match: invalid_attributes, format: :json }, session: valid_session
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
        { date: Time.zone.today + 1, location: "COPM" }
      end

      it "updates the requested match" do
        match = matches(:weekend_game)
        put :update, params: { id: match.to_param, match: new_attributes }, session: valid_session
        match.reload
        expect(match.date).to(eq(Time.zone.today + 1))
        expect(match.location).to(eq("COPM"))
      end

      it "redirects to the match" do
        match = matches(:weekend_game)
        put :update, params: { id: match.to_param, match: new_attributes }, session: valid_session
        expect(response).to(have_http_status(:see_other))
        expect(response).to(redirect_to(match))
      end

      it "responds with JSON format" do
        match = matches(:weekend_game)
        put :update, params: { id: match.to_param, match: new_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:ok))
        expect(response.body).not_to(be_empty)
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("id"))
      end
    end

    context "with invalid params" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        match = matches(:weekend_game)
        put :update, params: { id: match.to_param, match: invalid_attributes }, session: valid_session
        expect(response).to(have_http_status(:unprocessable_content))
      end

      it "responds with JSON format and errors" do
        match = matches(:weekend_game)
        put :update, params: { id: match.to_param, match: invalid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to(include("application/json"))
        expect(response).to(have_http_status(:unprocessable_content))
        parsed_response = response.parsed_body
        expect(parsed_response).to(be_a(Hash))
        expect(parsed_response).not_to(be_empty)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested match" do
      match = Match.create!(date: Time.zone.today, location: "Test Location")
      expect do
        delete(:destroy, params: { id: match.to_param }, session: valid_session)
      end.to(change(Match, :count).by(-1))
    end

    it "redirects to the matches list" do
      match = Match.create!(date: Time.zone.today, location: "Test Location")
      delete :destroy, params: { id: match.to_param }, session: valid_session
      expect(response).to(have_http_status(:see_other))
      expect(response).to(redirect_to(matches_path))
    end

    it "responds with JSON format" do
      match = Match.create!(date: Time.zone.today, location: "Test Location")
      delete :destroy, params: { id: match.to_param, format: :json }, session: valid_session
      expect(response).to(have_http_status(:no_content))
    end
  end
end
