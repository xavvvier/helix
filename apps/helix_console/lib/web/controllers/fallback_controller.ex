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

  def call(conn, {:error, %{valid?: false, errors: errors}}) when is_list(errors) do
    json_response = parse_validation_error(errors)
    conn
      |> put_status(500)
      |> json(json_response)
  end

  defp parse_validation_error(errors) do
    errors
    |> Enum.map(fn {field, {message, [{validation_key, validation_value}]}} -> 
      %{
        field: field,
        message: message,
        details: %{
          validation_key => validation_value
        }
      }
    end)
  end
end
