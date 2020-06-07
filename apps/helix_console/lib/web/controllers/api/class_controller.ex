defmodule Helix.WebConsole.Api.ClassController do
  use Helix.WebConsole, :controller

  alias Helix.Builder.Query
  alias Helix.Builder.Class
  alias Helix.Builder.Impl, as: Builder

  action_fallback Helix.WebConsole.FallbackController

  def index(conn, _params) do
    classes = Query.list_classes()
    render(conn, "index.json", classes: classes)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, class} <- Query.get_class(id) do
      render(conn, "show.json", class: class)
    end
  end

  def create(conn, %{"class" => params}) do
    with {:ok, class} <- Class.validate_params(params),
      {:ok, result} <- Builder.create_class(class) 
    do
      conn
      |> json(extract_id(result))
    end
  end

  defp extract_id(%{new_class: %{id: id}}) do
    %{class_id: id}
  end
end
