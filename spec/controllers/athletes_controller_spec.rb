require 'rails_helper'

RSpec.describe AthletesController, type: :controller do
  fixtures :transaction_categories, :athletes, :matches, :payments

  # Enable view rendering for JSON responses
  render_views

  let(:valid_attributes) {
    { name: 'Test Athlete', phone: 1234567890, date_of_birth: Date.today }
  }

  let(:invalid_attributes) {
    { name: '', phone: nil, date_of_birth: nil }
  }

  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: {}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      athlete = athletes(:john_doe)
      get :show, params: { id: athlete.to_param }, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      athlete = athletes(:john_doe)
      get :edit, params: { id: athlete.to_param }, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Athlete" do
        expect {
          post :create, params: { athlete: valid_attributes }, session: valid_session
        }.to change(Athlete, :count).by(1)
      end

      it "redirects to the created athlete" do
        post :create, params: { athlete: valid_attributes }, session: valid_session
        expect(response).to redirect_to(Athlete.last)
      end

      it "responds with JSON format" do
        post :create, params: { athlete: valid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to include('application/json')
        expect(response).to have_http_status(:created)
        expect(response.body).not_to be_empty
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('id')
      end
    end

    context "with invalid params" do
      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post :create, params: { athlete: invalid_attributes }, session: valid_session
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "responds with JSON format and errors" do
        post :create, params: { athlete: invalid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to include('application/json')
        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_a(Hash)
        expect(parsed_response).not_to be_empty
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        { name: 'Updated Athlete', phone: 9998887777, date_of_birth: Date.today - 1 }
      }

      it "updates the requested athlete" do
        athlete = athletes(:john_doe)
        put :update, params: { id: athlete.to_param, athlete: new_attributes }, session: valid_session
        athlete.reload
        expect(athlete.name).to eq('Updated Athlete')
        expect(athlete.phone).to eq(9998887777)
        expect(athlete.date_of_birth).to eq(Date.today - 1)
      end

      it "redirects to the athlete" do
        athlete = athletes(:john_doe)
        put :update, params: { id: athlete.to_param, athlete: new_attributes }, session: valid_session
        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(athlete)
      end

      it "responds with JSON format" do
        athlete = athletes(:john_doe)
        put :update, params: { id: athlete.to_param, athlete: new_attributes, format: :json }, session: valid_session
        expect(response.content_type).to include('application/json')
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to be_empty
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('id')
      end
    end

    context "with invalid params" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        athlete = athletes(:john_doe)
        put :update, params: { id: athlete.to_param, athlete: invalid_attributes }, session: valid_session
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "responds with JSON format and errors" do
        athlete = athletes(:john_doe)
        put :update, params: { id: athlete.to_param, athlete: invalid_attributes, format: :json }, session: valid_session
        expect(response.content_type).to include('application/json')
        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_a(Hash)
        expect(parsed_response).not_to be_empty
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested athlete" do
      athlete = Athlete.create!(name: 'Test Athlete', phone: 1112223333, date_of_birth: Date.today)
      expect {
        delete :destroy, params: { id: athlete.to_param }, session: valid_session
      }.to change(Athlete, :count).by(-1)
    end

    it "redirects to the athletes list" do
      athlete = Athlete.create!(name: 'Test Athlete', phone: 1112223333, date_of_birth: Date.today)
      delete :destroy, params: { id: athlete.to_param }, session: valid_session
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(athletes_path)
    end

    it "responds with JSON format" do
      athlete = Athlete.create!(name: 'Test Athlete', phone: 1112223333, date_of_birth: Date.today)
      delete :destroy, params: { id: athlete.to_param, format: :json }, session: valid_session
      expect(response).to have_http_status(:no_content)
    end
  end
end
