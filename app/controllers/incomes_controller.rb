class IncomesController < ApplicationController
  before_action :set_income, only: %i[ show edit update destroy ]

  def index
    @incomes = Income.all
  end

  def show
  end

  def new
    @income = Income.new
  end

  def edit
  end

  def create
    @income = Income.new(income_params)

    respond_to do |format|
      if @income.save
        format.html { redirect_to @income, notice: "Income was successfully created." }
        format.json { render :show, status: :created, location: @income }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @income.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @income.update(income_params)
        format.html { redirect_to @income, notice: "Income was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @income }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @income.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @income.destroy!

    respond_to do |format|
      format.html { redirect_to incomes_path, notice: "Income was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_income
      @income = Income.find(params[:id])
    end

    def income_params
      params.require(:income).permit(:unit_value, :date, :transaction_category_id)
    end
end
