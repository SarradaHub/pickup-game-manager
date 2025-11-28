module ApplicationHelper
  # Currency and date formatting constants
  CURRENCY_PRECISION = 2
  DATE_FORMAT = "%d/%m/%Y".freeze
  DATE_FORMAT_LONG = "%A, %d de %B de %Y".freeze

  def button_classes(variant: :primary, size: :base)
    base_classes = "inline-flex items-center justify-center rounded-lg font-medium " \
                   "focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors gap-2"

    # Normalize variant to default if not recognized
    variant = :primary unless %i(primary secondary error danger).include?(variant)

    variant_classes = case variant
                      when :primary
                        "bg-secondary-600 text-white hover:bg-secondary-700 " \
                        "focus:ring-secondary-500 active:bg-secondary-800"
                      when :secondary
                        "bg-neutral-200 text-neutral-900 hover:bg-neutral-300 " \
                        "focus:ring-neutral-500 active:bg-neutral-400"
                      when :error, :danger
                        "bg-error-600 text-white hover:bg-error-700 " \
                        "focus:ring-error-500 active:bg-error-800"
                      end

    # Normalize size to default if not recognized
    size = :base unless %i(sm base lg).include?(size)

    size_classes = {
      sm: "px-3 py-1.5 text-sm gap-1.5",
      base: "px-4 py-2 text-base gap-2",
      lg: "px-6 py-3 text-lg gap-2",
    }[size]

    "#{base_classes} #{variant_classes} #{size_classes}"
  end
end
