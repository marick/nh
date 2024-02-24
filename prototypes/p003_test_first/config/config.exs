import Config


config :logger, :default_formatter,
       format: {AppAnimal.Pretty.LogFormat, :format},
       metadata: [:error_code, :mfa, :newlines]
