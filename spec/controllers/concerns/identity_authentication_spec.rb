require "rails_helper"

RSpec.describe(IdentityAuthentication, type: :controller) do
  # Create a test controller that includes the concern
  controller(ApplicationController) do
    include IdentityAuthentication

    def index
      render(json: { message: "success", user: current_user })
    end

    def requires_authentication?
      true
    end
  end

  let(:valid_token) { "valid_token_123" }
  let(:invalid_token) { "invalid_token_456" }
  let(:valid_user) { { id: 1, email: "test@example.com" } }

  describe "#authenticate_user" do
    context "with valid token" do
      before do
        allow(IdentityServiceClient).to receive(:validate_token).with(valid_token).and_return({
          valid: true,
          user: valid_user,
        })
        request.headers["Authorization"] = "Bearer #{valid_token}"
      end

      it "sets @current_user" do
        get :index
        expect(controller.instance_variable_get(:@current_user)).to(eq(valid_user))
      end

      it "allows the action to proceed" do
        get :index
        expect(response).to(be_successful)
      end

      it "makes current_user available" do
        get :index
        parsed_response = response.parsed_body
        # The controller action renders the user, so we can check it's available
        # JSON responses use string keys, not symbol keys
        expect(parsed_response).to(have_key("user"))
        expect(parsed_response["user"]["id"]).to(eq(valid_user[:id]))
        expect(parsed_response["user"]["email"]).to(eq(valid_user[:email]))
      end
    end

    context "with invalid token" do
      before do
        allow(IdentityServiceClient).to receive(:validate_token).with(invalid_token).and_return({
          valid: false,
          error: "Invalid token",
        })
        request.headers["Authorization"] = "Bearer #{invalid_token}"
      end

      it "renders unauthorized" do
        get :index
        expect(response).to(have_http_status(:unauthorized))
      end

      it "returns JSON error response" do
        get :index
        parsed_response = response.parsed_body
        expect(parsed_response).to(have_key("success"))
        expect(parsed_response["success"]).to(be(false))
        expect(parsed_response).to(have_key("code"))
        expect(parsed_response["code"]).to(eq("UNAUTHORIZED"))
      end
    end

    context "without token" do
      it "renders unauthorized" do
        get :index
        expect(response).to(have_http_status(:unauthorized))
      end

      it "does not call IdentityServiceClient" do
        expect(IdentityServiceClient).not_to(receive(:validate_token))
        get :index
      end
    end

    context "with blank token" do
      before do
        allow(IdentityServiceClient).to receive(:validate_token).with("").and_return({
          valid: false,
          error: "Token required",
        })
        request.headers["Authorization"] = "Bearer "
      end

      it "renders unauthorized" do
        get :index
        expect(response).to(have_http_status(:unauthorized))
      end
    end
  end

  describe "#extract_token_from_header" do
    it "extracts token from Bearer authorization header" do
      request.headers["Authorization"] = "Bearer test_token_123"
      token = controller.send(:extract_token_from_header)
      expect(token).to(eq("test_token_123"))
    end

    it "returns nil when Authorization header is missing" do
      # Remove the header by setting it to nil
      request.headers["Authorization"] = nil
      token = controller.send(:extract_token_from_header)
      expect(token).to(be_nil)
    end

    it "returns nil when Authorization header is not Bearer format" do
      request.headers["Authorization"] = "Basic dGVzdDp0ZXN0"
      token = controller.send(:extract_token_from_header)
      expect(token).to(be_nil)
    end

    it "returns nil when Authorization header has extra words (not exactly 2 parts)" do
      request.headers["Authorization"] = "Bearer token extra"
      token = controller.send(:extract_token_from_header)
      # The method only extracts if there are exactly 2 parts (Bearer + token)
      # With extra words, parts.length != 2, so it returns nil
      expect(token).to(be_nil)
    end

    it "handles single word Authorization header" do
      request.headers["Authorization"] = "Bearer"
      token = controller.send(:extract_token_from_header)
      expect(token).to(be_nil)
    end
  end

  describe "#render_unauthorized" do
    it "renders JSON with unauthorized status" do
      # Test by triggering authentication failure
      get :index
      expect(response).to(have_http_status(:unauthorized))
      parsed_response = response.parsed_body
      expect(parsed_response).to(have_key("success"))
      expect(parsed_response["success"]).to(be(false))
      expect(parsed_response).to(have_key("message"))
      expect(parsed_response["message"]).to(eq("Unauthorized"))
      expect(parsed_response).to(have_key("code"))
      expect(parsed_response["code"]).to(eq("UNAUTHORIZED"))
    end
  end

  describe "#current_user" do
    it "returns @current_user" do
      user = { id: 1, email: "test@example.com" }
      controller.instance_variable_set(:@current_user, user)
      expect(controller.send(:current_user)).to(eq(user))
    end

    it "returns nil when @current_user is not set" do
      expect(controller.send(:current_user)).to(be_nil)
    end
  end

  describe "#requires_authentication?" do
    it "returns true by default" do
      # Create a controller that doesn't override requires_authentication?
      controller_class = Class.new(ApplicationController) do
        include IdentityAuthentication
      end

      test_controller = controller_class.new
      expect(test_controller.send(:requires_authentication?)).to(be(true))
    end

    it "can be overridden in controller" do
      controller_class = Class.new(ApplicationController) do
        include IdentityAuthentication

        def requires_authentication?
          false
        end
      end

      test_controller = controller_class.new
      expect(test_controller.send(:requires_authentication?)).to(be(false))
    end
  end
end

