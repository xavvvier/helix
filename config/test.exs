use Mix.Config

config :builder, Helix.Builder.Repo,
  database: "helix_test",
  username: "xavvvier",
  password: "",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :helix_console, Helix.WebConsole.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
