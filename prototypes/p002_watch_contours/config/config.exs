import Config


config :logger, :default_formatter,
  format: {MyFormat, :format},
  metadata: [:error_code, :mfa, :newlines]
