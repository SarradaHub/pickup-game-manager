require "rails_helper"

RSpec.describe(IdentityServiceClient) do
  describe ".validate_token" do
    context "with blank token" do
      it "returns invalid with error message" do
        result = described_class.validate_token("")
        expect(result).to(eq({ valid: false, error: "Token required" }))
      end

      it "returns invalid for nil token" do
        result = described_class.validate_token(nil)
        expect(result).to(eq({ valid: false, error: "Token required" }))
      end
    end

    context "when identity service is not configured" do
      before do
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", anything).and_return("")
      end

      it "returns invalid with error message" do
        result = described_class.validate_token("valid_token")
        expect(result).to(eq({ valid: false, error: "Identity service not configured" }))
      end
    end

    context "with valid token and successful response" do
      let(:valid_token) { "valid_token_123" }
      let(:user_data) { { id: 1, email: "test@example.com" } }
      let(:successful_response) do
        {
          success: true,
          data: {
            "success" => true,
            "data" => {
              "user" => user_data,
            },
          },
        }
      end

      before do
        allow(CircuitBreakerService).to receive(:call_service).and_return(successful_response)
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", "http://identity-service:3001").and_return("http://identity-service:3001")
      end

      it "returns valid with user data" do
        result = described_class.validate_token(valid_token)
        expect(result).to(eq({ valid: true, user: user_data }))
      end

      it "calls CircuitBreakerService with correct parameters" do
        described_class.validate_token(valid_token)
        expect(CircuitBreakerService).to have_received(:call_service).with(
          "identity-service",
          method: :post,
          path: "/api/v1/auth/validate",
          params: { token: valid_token },
          headers: { "Content-Type" => "application/json" },
        )
      end
    end

    context "with failed response" do
      let(:failed_response) do
        {
          success: false,
          error: "Service unavailable",
        }
      end

      before do
        allow(CircuitBreakerService).to receive(:call_service).and_return(failed_response)
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", "http://identity-service:3001").and_return("http://identity-service:3001")
      end

      it "returns invalid with error from response" do
        result = described_class.validate_token("token")
        expect(result).to(eq({ valid: false, error: "Service unavailable" }))
      end
    end

    context "when response success is false in data" do
      let(:response_with_false_success) do
        {
          success: true,
          data: {
            "success" => false,
          },
        }
      end

      before do
        allow(CircuitBreakerService).to receive(:call_service).and_return(response_with_false_success)
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", "http://identity-service:3001").and_return("http://identity-service:3001")
      end

      it "returns invalid with default error message" do
        result = described_class.validate_token("token")
        expect(result).to(eq({ valid: false, error: "Token validation failed" }))
      end
    end

    context "when an exception is raised" do
      before do
        allow(CircuitBreakerService).to receive(:call_service).and_raise(StandardError.new("Network error"))
        allow(Rails.logger).to receive(:error)
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", "http://identity-service:3001").and_return("http://identity-service:3001")
      end

      it "returns invalid with error message" do
        result = described_class.validate_token("token")
        expect(result).to(eq({ valid: false, error: "Network error" }))
      end

      it "logs the error" do
        described_class.validate_token("token")
        expect(Rails.logger).to have_received(:error).with("Identity service validation error: Network error")
      end
    end
  end

  describe ".get_user" do
    context "when identity service is not configured" do
      before do
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", anything).and_return("")
      end

      it "returns nil" do
        result = described_class.get_user(1)
        expect(result).to(be_nil)
      end
    end

    context "with successful response" do
      let(:user_id) { 1 }
      let(:user_data) { { id: 1, email: "test@example.com", name: "Test User" } }
      let(:successful_response) do
        {
          success: true,
          data: {
            "data" => user_data,
          },
        }
      end

      before do
        allow(CircuitBreakerService).to receive(:call_service).and_return(successful_response)
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", "http://identity-service:3001").and_return("http://identity-service:3001")
        allow(ENV).to receive(:fetch).with("SERVICE_API_KEY", "").and_return("api_key_123")
      end

      it "returns user data" do
        result = described_class.get_user(user_id)
        expect(result).to(eq(user_data))
      end

      it "calls CircuitBreakerService with correct parameters" do
        described_class.get_user(user_id)
        expect(CircuitBreakerService).to have_received(:call_service).with(
          "identity-service",
          method: :get,
          path: "/api/v1/users/#{user_id}",
          headers: { "Authorization" => "Bearer api_key_123" },
        )
      end
    end

    context "with failed response" do
      let(:failed_response) do
        {
          success: false,
          error: "User not found",
        }
      end

      before do
        allow(CircuitBreakerService).to receive(:call_service).and_return(failed_response)
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", "http://identity-service:3001").and_return("http://identity-service:3001")
        allow(ENV).to receive(:fetch).with("SERVICE_API_KEY", "").and_return("api_key_123")
      end

      it "returns nil" do
        result = described_class.get_user(1)
        expect(result).to(be_nil)
      end
    end

    context "when an exception is raised" do
      before do
        allow(CircuitBreakerService).to receive(:call_service).and_raise(StandardError.new("Connection error"))
        allow(Rails.logger).to receive(:error)
        allow(ENV).to receive(:fetch).with("IDENTITY_SERVICE_URL", "http://identity-service:3001").and_return("http://identity-service:3001")
        allow(ENV).to receive(:fetch).with("SERVICE_API_KEY", "").and_return("api_key_123")
      end

      it "returns nil" do
        result = described_class.get_user(1)
        expect(result).to(be_nil)
      end

      it "logs the error" do
        described_class.get_user(1)
        expect(Rails.logger).to have_received(:error).with("Identity service get_user error: Connection error")
      end
    end
  end
end

