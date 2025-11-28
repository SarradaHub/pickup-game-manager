# Consul service registration
if Rails.env.production? || ENV["CONSUL_ENABLED"] == "true"
  Rails.application.config.after_initialize do
    ConsulService.register_service
  rescue StandardError => e
    Rails.logger.error("Failed to initialize Consul: #{e.message}")
  end

  # Deregister on shutdown
  at_exit do
    ConsulService.deregister_service
  end
end
