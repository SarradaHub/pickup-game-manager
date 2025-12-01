require "rails_helper"

RSpec.describe(HealthController, type: :controller) do
  render_views

  describe "GET #health" do
    it "returns a success response" do
      get :health
      expect(response).to(be_successful)
    end

    it "returns JSON response" do
      get :health
      expect(response.content_type).to(include("application/json"))
    end

    it "returns status ok" do
      get :health
      parsed_response = response.parsed_body
      expect(parsed_response).to(have_key("status"))
      expect(parsed_response["status"]).to(eq("ok"))
    end

    it "returns service name" do
      get :health
      parsed_response = response.parsed_body
      expect(parsed_response).to(have_key("service"))
      expect(parsed_response["service"]).to(eq("pickup-game-manager"))
    end

    it "returns timestamp" do
      get :health
      parsed_response = response.parsed_body
      expect(parsed_response).to(have_key("timestamp"))
      expect(parsed_response["timestamp"]).to(be_a(String))
    end

    it "returns environment" do
      get :health
      parsed_response = response.parsed_body
      expect(parsed_response).to(have_key("environment"))
      expect(parsed_response["environment"]).to(eq(Rails.env))
    end

    it "returns ISO8601 formatted timestamp" do
      get :health
      parsed_response = response.parsed_body
      timestamp = parsed_response["timestamp"]
      expect { Time.iso8601(timestamp) }.not_to(raise_error)
    end
  end

  describe "GET #ready" do
    context "when database is available" do
      it "returns a success response" do
        get :ready
        expect(response).to(be_successful)
      end

      it "returns JSON response" do
        get :ready
        expect(response.content_type).to(include("application/json"))
      end

      it "returns status ready" do
        get :ready
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("status"))
        expect(parsed_response["status"]).to(eq("ready"))
      end

      it "returns service name" do
        get :ready
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("service"))
        expect(parsed_response["service"]).to(eq("pickup-game-manager"))
      end

      it "returns timestamp" do
        get :ready
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("timestamp"))
        expect(parsed_response["timestamp"]).to(be_a(String))
      end

      it "does not include error key when successful" do
        get :ready
        parsed_response = response.parsed_body
        expect(parsed_response).not_to(have_key("error"))
      end
    end

    context "when database connection fails" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError.new("Connection failed"))
      end

      it "returns service_unavailable status" do
        get :ready
        expect(response).to(have_http_status(:service_unavailable))
      end

      it "returns JSON response with error" do
        get :ready
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("status"))
        expect(parsed_response["status"]).to(eq("not ready"))
      end

      it "includes error message" do
        get :ready
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("error"))
        expect(parsed_response["error"]).to(include("Database connection failed"))
      end

      it "includes service name in error response" do
        get :ready
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("service"))
        expect(parsed_response["service"]).to(eq("pickup-game-manager"))
      end
    end
  end
end

