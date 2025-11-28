module IconHelper
  # Size mapping for Font Awesome icons
  SIZE_CLASSES = {
    "xs" => "text-xs",
    "sm" => "text-sm",
    "md" => "text-base",
    "lg" => "text-lg",
    "xl" => "text-xl",
    "2xl" => "text-2xl",
  }.freeze

  # Icon name mapping from emoji to Font Awesome icon names
  EMOJI_TO_ICON = {
    "💰" => "dollar-sign",
    "💸" => "arrow-trend-down",
    "📈" => "arrow-trend-up",
    "📊" => "chart-bar",
    "👥" => "users",
    "⚽" => "futbol",
    "⏳" => "clock",
    "👤" => "user",
    "💳" => "credit-card",
    "📝" => "file-lines",
    "⚖️" => "scale-balanced",
  }.freeze

  # Renders a Font Awesome icon
  # @param icon_name [String] The name of the icon (e.g., 'user', 'dollar-sign') or emoji
  # @param size [String] Size of the icon: 'xs', 'sm', 'md', 'lg', 'xl', '2xl' (default: 'md')
  # @param class_name [String] Additional CSS classes
  # @param aria_label [String] Optional aria-label for accessibility
  # @param aria_hidden [Boolean] Whether to hide from screen readers (default: true if no aria-label)
  def icon(icon_name, size: "md", class_name: nil, aria_label: nil, aria_hidden: nil)
    # Convert emoji to Font Awesome icon name if needed
    fa_icon_name = EMOJI_TO_ICON[icon_name] || icon_name

    # Get size class
    size_class = SIZE_CLASSES[size] || SIZE_CLASSES["md"]

    # Build class string for Font Awesome
    fa_classes = ["fa-solid", "fa-#{fa_icon_name}", size_class, class_name].compact.join(" ")

    # Determine aria-hidden
    hidden = aria_hidden.nil? ? aria_label.blank? : aria_hidden

    # Build attributes
    attrs = {
      class: fa_classes,
    }
    attrs["aria-label"] = aria_label if aria_label.present?
    attrs["aria-hidden"] = "true" if hidden

    # Render Font Awesome icon
    content_tag(:i, "", attrs)
  end
end
