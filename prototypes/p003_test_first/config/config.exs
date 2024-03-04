import Config

config :logger, :default_formatter,
       format: {AppAnimal.Pretty.LogFormat, :format},
       metadata: [:mfa, :newlines, :pulse_entry]

config :logger, level: :info

