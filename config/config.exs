# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :builder, ecto_repos: [Helix.Builder.Repo]

# Configures the endpoint
config :helix_console, Helix.WebConsole.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "X5ZHo5xYGew2kz00Jz3j8f1yJ41+9O7E2GDmfJGVD/nZ0/cGgOE4qui4v7CDuWAv",
  render_errors: [view: Helix.WebConsole.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Helix.WebConsole.PubSub,
  live_view: [signing_salt: "J+5V5zGd"]

# Configures Elixir's Logger
config :logger, :helix_console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
