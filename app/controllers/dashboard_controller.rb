class DashboardController < ApplicationController
  def index
    load_quick_stats
    load_recent_activity
    equilibrium_point
    monthly_summary
    yearly_summary
    debtors
  end

  def equilibrium_point
    @income_types = params[:income_types] || []
    @expenses_types = params[:expenses_types] || []
    @equilibrium_point = EquilibriumPoint.calculate_equilibrium_point_with_details(@income_types, @expenses_types)

    @available_income_types = TransactionCategory.pluck(:name)
    @available_expense_types = Expense.distinct.pluck(:type)
  end

  private

  def monthly_summary
    @monthly_summary = FinancialSummary.period_summary(Date.today.beginning_of_month..Date.today.end_of_month)
  end

  def yearly_summary
    @yearly_summary = FinancialSummary.period_summary(Date.today.beginning_of_year..Date.today.end_of_year)
  end

  def load_quick_stats
    @total_athletes = Athlete.count
    @upcoming_matches = Match.where("date >= ?", Date.today).order(:date).limit(5)
    @pending_payments = Payment.pending.count
    @total_matches = Match.count
  end

  def load_recent_activity
    @recent_payments = Payment.includes(:athlete, :match).order(created_at: :desc).limit(5)
    @recent_expenses = Expense.order(created_at: :desc).limit(5)
    @recent_athletes = Athlete.order(created_at: :desc).limit(5)
  end

  def debtors
    @debtors = Athlete.joins(:payments)
                      .where(payments: { status: "pending" })
                      .includes(:payments, :matches)
  end
end
