# frozen_string_literal: true

# Workaround for Rails 8.1 frozen autoload paths issue with engines
# Rails 8.1 freezes autoload paths, but engines (solid_cache, solid_queue, solid_cable)
# try to modify them using unshift, which causes a FrozenError.
# This patch intercepts Array#unshift calls on frozen autoload paths arrays.

# Patch Array#unshift to handle frozen autoload paths
Array.class_eval do
  alias_method :original_unshift, :unshift unless method_defined?(:original_unshift)

  def unshift(*args)
    # Check if this is a frozen autoload paths array
    if frozen? && defined?(Rails) && Rails.application &&
       self.equal?(Rails.application.config.autoload_paths)
      # Make it mutable and then unshift
      Rails.application.config.autoload_paths = dup
      Rails.application.config.autoload_paths.unshift(*args)
    else
      original_unshift(*args)
    end
  end
end
