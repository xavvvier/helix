use Mix.Config

config :builder, Helix.Builder.Repo,
  database: "helix_test",
  username: "xavvvier",
  password: "",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox


