module Api
  module V1
    class AthletesController < BaseController
      before_action :set_athlete, only: [:show, :update, :destroy]

      def index
        @athletes = Athlete.all
        render json: @athletes
      end

      def show
        render json: @athlete
      end

      def create
        @athlete = Athlete.new(athlete_params)
        if @athlete.save
          render json: @athlete, status: :created
        else
          render json: @athlete.errors, status: :unprocessable_entity
        end
      end

      def update
        if @athlete.update(athlete_params)
          render json: @athlete
        else
          render json: @athlete.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @athlete.destroy
        head :no_content
      end

      private

      def set_athlete
        @athlete = Athlete.find(params[:id])
      end

      def athlete_params
        params.require(:athlete).permit(:name, :email, :phone)
      end
    end
  end
end

