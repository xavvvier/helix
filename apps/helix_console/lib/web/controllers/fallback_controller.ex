defmodule Helix.WebConsole.FallbackController do
  use Helix.WebConsole, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(Helix.WebConsole.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unathorized}) do
    conn
    |> put_status(403)
    |> put_view(Helix.WebConsole.ErrorView)
    |> render(:"403")
  end
end