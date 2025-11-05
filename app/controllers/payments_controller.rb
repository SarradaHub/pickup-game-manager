class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[ show edit update destroy ]

  def index
    @payments = Payment.all
  end

  def show
  end

  def new
    @payment = Payment.new
  end

  def edit
  end

  def create
    @payment = Payment.new(payment_params)

    respond_to do |format|
      if @payment.save
        format.html { redirect_to @payment, notice: "Payment was successfully created." }
        format.json { render :show, status: :created, location: @payment }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @payment.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @payment.update(payment_params)
        format.html { redirect_to @payment, notice: "Payment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @payment }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @payment.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @payment.destroy!

    respond_to do |format|
      format.html { redirect_to payments_path, notice: "Payment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_payment
      @payment = Payment.find(params[:id])
    end

    def payment_params
      params.require(:payment).permit(:date, :status, :athlete_id, :match_id, :transaction_category_id, :description, :amount)
    end
end
