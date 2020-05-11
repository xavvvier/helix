use Mix.Config

config :builder, Helix.Builder.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "helix",
  username: "xavvvier",
  password: "",
  hostname: "localhost"

