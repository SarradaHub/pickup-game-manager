class AthletesController < ApplicationController
  before_action :set_athlete, only: %i[ show edit update destroy ]

  def index
    @athletes = Athlete.all
  end

  def show
  end

  def new
    @athlete = Athlete.new
  end

  def edit
  end

  def create
    @athlete = Athlete.new(athlete_params)

    respond_to do |format|
      if @athlete.save
        format.html { redirect_to @athlete, notice: "Athlete was successfully created." }
        format.json { render :show, status: :created, location: @athlete }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @athlete.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @athlete.update(athlete_params)
        format.html { redirect_to @athlete, notice: "Athlete was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @athlete }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @athlete.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @athlete.destroy!

    respond_to do |format|
      format.html { redirect_to athletes_path, notice: "Athlete was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_athlete
      @athlete = Athlete.find(params[:id])
    end

    def athlete_params
      params.require(:athlete).permit(:name, :phone, :date_of_birth)
    end
end
