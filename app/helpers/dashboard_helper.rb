module DashboardHelper
  def calculate_bar_height(value, total)
    return 0 if total.zero?

    [(value.to_f / total * 100).round(1), 100].min
  end

  def currency_with_color(value, positive_color: "text-success-600", negative_color: "text-error-600")
    color_class = value >= 0 ? positive_color : negative_color
    content_tag(:span, "R$#{number_with_precision(value, precision: 2)}", class: color_class)
  end
end
