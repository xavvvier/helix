defmodule HX.Repo do
  use Ecto.Repo,
    otp_app: :helix,
    adapter: Ecto.Adapters.Postgres
end
