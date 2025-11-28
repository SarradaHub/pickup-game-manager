class FinancialSummary
  def self.period_summary(date_range)
    {
      income: payment_return(date_range),
      income_value: payment_return_value(payment_return(date_range)),
      expenses: expense_return(date_range),
      expenses_value: expense_return_value(expense_return(date_range)),
      profit: calculate_profit(date_range),
    }
  end

  def self.payment_return(date_range)
    Payment.where(date: date_range, status: "paid")
  end

  def self.payment_return_value(payments)
    payments.sum(:amount)
  end

  def self.expense_return(date_range)
    Expense.where(date: date_range)
  end

  def self.expense_return_value(expenses)
    expenses.sum do |expense|
      expense.unit_value * expense.quantity
    end
  end

  def self.calculate_profit(date_range)
    payment_return_value(payment_return(date_range)) - expense_return_value(expense_return(date_range))
  end
end
