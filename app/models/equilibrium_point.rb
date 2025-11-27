# EquilibriumPoint model for calculating financial equilibrium
class EquilibriumPoint
  def self.calculate_equilibrium_point(income_types = nil, expenses_types = nil)
    # If a parameter is nil, use defaults; otherwise use the provided value (including empty arrays)
    income_types = TransactionCategory.pluck(:name) if income_types.nil?
    expenses_types = Expense.distinct.pluck(:type).compact if expenses_types.nil?

    income_total = income_value(income_types)
    expenses_total = expenses_value(expenses_types)

    return 0 if income_total.zero? || income_types.empty?

    equilibrium = (expenses_total / income_total).ceil

    equilibrium.to_i
  end

  def self.calculate_equilibrium_point_with_details(income_types = nil, expenses_types = nil)
    # If a parameter is nil, use defaults; otherwise use the provided value (including empty arrays)
    income_types = TransactionCategory.pluck(:name) if income_types.nil?
    expenses_types = Expense.distinct.pluck(:type).compact if expenses_types.nil?

    income_data = self.income_data(income_types)
    expenses_data = self.expenses_data(expenses_types)

    if income_data[:total].zero? || income_types.empty?
      return { equilibrium_point: 0, income_total: 0, expenses_total: 0, income_unit_values: {},
               expenses_unit_values: {}, expenses_by_type: {}, income_count: 0, expenses_count: 0 }
    end

    equilibrium_point = (expenses_data[:total] / income_data[:total]).ceil

    {
      equilibrium_point: equilibrium_point.to_i,
      income_total: income_data[:total],
      expenses_total: expenses_data[:total],
      income_unit_values: income_data[:unit_values],
      expenses_unit_values: expenses_data[:unit_values],
      expenses_by_type: expenses_data[:expenses_by_type],
      income_count: income_types.count,
      expenses_count: expenses_types.count,
    }
  end

  def self.income_value(types)
    return 0 if types.empty?

    Income.joins(:transaction_category)
          .where(transaction_categories: { name: types })
          .sum(:unit_value)
  end

  def self.expenses_value(types)
    return 0 if types.empty?

    Expense.where(type: types).sum { |expense| expense.unit_value * expense.quantity }
  end

  def self.income_data(types)
    return { total: 0, unit_values: {} } if types.empty?

    incomes = Income.includes(:transaction_category)
                    .joins(:transaction_category)
                    .where(transaction_categories: { name: types })
                    .to_a

    # Group incomes in memory by category name
    incomes_by_type = incomes.group_by { |income| income.transaction_category.name }

    total = incomes.sum(&:unit_value)
    unit_values = {}

    types.each do |type|
      type_incomes = incomes_by_type[type] || []
      next if type_incomes.empty?

      unit_values[type] = {
        unit_value: (type_incomes.sum(&:unit_value).to_f / type_incomes.count).round(2),
        count: type_incomes.count,
        total_value: type_incomes.sum(&:unit_value),
      }
    end

    { total: total, unit_values: unit_values }
  end

  def self.expenses_data(types)
    return { total: 0, unit_values: {}, expenses_by_type: {} } if types.empty?

    expenses = Expense.where(type: types).order(:date).to_a

    # Group expenses in memory by type
    expenses_by_type = expenses.group_by(&:type)

    total = expenses.sum { |expense| expense.unit_value * expense.quantity }
    unit_values = {}
    expenses_by_type_detail = {}

    types.each do |type|
      type_expenses = expenses_by_type[type] || []
      next if type_expenses.empty?

      total_value = type_expenses.sum { |expense| expense.unit_value * expense.quantity }
      total_quantity = type_expenses.sum(&:quantity)

      unit_values[type] = {
        unit_value: (total_quantity.positive? ? (total_value.to_f / total_quantity).round(2) : 0.0),
        count: type_expenses.count,
        total_value: total_value,
      }

      # Include detailed expense information grouped by type
      expenses_by_type_detail[type] = type_expenses.map do |expense|
        {
          id: expense.id,
          description: expense.description,
          unit_value: expense.unit_value,
          quantity: expense.quantity,
          total_value: expense.total_value,
          date: expense.date
        }
      end
    end

    { total: total, unit_values: unit_values, expenses_by_type: expenses_by_type_detail }
  end

  # Get metadata for all available income types (not just selected ones)
  def self.all_income_types_metadata
    all_types = TransactionCategory.all.includes(:incomes)
    metadata = {}

    all_types.each do |category|
      incomes = category.incomes.to_a
      next if incomes.empty?

      metadata[category.name] = {
        name: category.name,
        description: category.description || '',
        avg_unit_value: (incomes.sum(&:unit_value).to_f / incomes.count).round(2),
        total_value: incomes.sum(&:unit_value),
        record_count: incomes.count
      }
    end

    metadata
  end

  # Get metadata for all available expense types (not just selected ones)
  def self.all_expense_types_metadata
    all_types = Expense.distinct.pluck(:type).compact
    metadata = {}

    all_types.each do |type|
      expenses = Expense.where(type: type).to_a
      next if expenses.empty?

      total_value = expenses.sum { |expense| expense.unit_value * expense.quantity }
      total_quantity = expenses.sum(&:quantity)

      metadata[type] = {
        type: type,
        avg_unit_value: (total_quantity.positive? ? (total_value.to_f / total_quantity).round(2) : 0.0),
        total_value: total_value,
        record_count: expenses.count,
        total_quantity: total_quantity
      }
    end

    metadata
  end
end
