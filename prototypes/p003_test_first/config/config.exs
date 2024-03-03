import Config

config :logger, :default_formatter,
       format: {AppAnimal.Pretty.LogFormat, :format},
       metadata: [:mfa, :newlines, :cluster]

config :logger, level: :info

