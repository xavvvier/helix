# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :helix,
  namespace: HX,
  ecto_repos: [HX.Repo]

config :helix_web,
  namespace: HXWeb,
  ecto_repos: [HX.Repo],
  generators: [context_app: :helix]

# Configures the endpoint
config :helix_web, HXWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "m62qVsvAWNox9n7CeYE2wyVLzW2hBVvruSvnsXyg9Sbt9USD1027Mq38ULPhlynR",
  render_errors: [view: HXWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HX.PubSub,
  live_view: [signing_salt: "tgImn5kn"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
