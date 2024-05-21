import Config

config :logger, :default_formatter,
       format: {AppAnimal.Pretty.LogFormat, :format},
       metadata: [:mfa, :newlines, :moveable]

config :logger, level: :info

