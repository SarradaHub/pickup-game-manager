class DashboardController < ApplicationController
  # Display limits
  UPCOMING_MATCHES_LIMIT = 5
  RECENT_ITEMS_LIMIT = 5
  DEBTORS_DISPLAY_LIMIT = 10

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
    
    # Provide metadata for all available options
    @income_types_metadata = EquilibriumPoint.all_income_types_metadata
    @expense_types_metadata = EquilibriumPoint.all_expense_types_metadata
  end

  def calculate_equilibrium
    income_types = params[:income_types] || []
    expenses_types = params[:expenses_types] || []
    
    result = EquilibriumPoint.calculate_equilibrium_point_with_details(income_types, expenses_types)
    
    render json: {
      equilibrium_point: result[:equilibrium_point],
      income_total: result[:income_total],
      expenses_total: result[:expenses_total],
      income_unit_values: result[:income_unit_values],
      expenses_unit_values: result[:expenses_unit_values],
      expenses_by_type: result[:expenses_by_type],
      income_count: result[:income_count],
      expenses_count: result[:expenses_count],
      selected_income_types: income_types,
      selected_expense_types: expenses_types
    }
  end

  private

  def monthly_summary
    @monthly_summary = FinancialSummary.period_summary(Time.zone.today.all_month)
  end

  def yearly_summary
    @yearly_summary = FinancialSummary.period_summary(Time.zone.today.all_year)
  end

  def load_quick_stats
    @total_athletes = Athlete.count
    @upcoming_matches = Match.where(date: Time.zone.today..).order(:date).limit(UPCOMING_MATCHES_LIMIT)
    @pending_payments = Payment.pending.count
    @total_matches = Match.count
    @upcoming_matches_limit = UPCOMING_MATCHES_LIMIT
  end

  def load_recent_activity
    @recent_payments = Payment.includes(:athlete, :match).order(created_at: :desc).limit(RECENT_ITEMS_LIMIT)
    @recent_expenses = Expense.order(created_at: :desc).limit(RECENT_ITEMS_LIMIT)
    @recent_athletes = Athlete.order(created_at: :desc).limit(RECENT_ITEMS_LIMIT)
    @recent_items_limit = RECENT_ITEMS_LIMIT
  end

  def debtors
    @debtors = Athlete.joins(:payments)
                      .where(payments: { status: "pending" })
                      .includes(:payments, :matches)
    @debtors_display_limit = DEBTORS_DISPLAY_LIMIT
  end
end
