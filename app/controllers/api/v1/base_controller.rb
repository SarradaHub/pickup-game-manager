module Api
  module V1
    class BaseController < ApplicationController
      include IdentityAuthentication

      protect_from_forgery with: :null_session

      private

      def requires_authentication?
        true
      end
    end
  end
end
