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

  def call(conn, {:error, _error_type, %Ecto.Changeset{} = changeset}) do
    call(conn, {:error, changeset})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    json_response = parse_validation_error(changeset)
    conn
      |> put_status(500)
      |> json(json_response)
  end

  defp parse_validation_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
