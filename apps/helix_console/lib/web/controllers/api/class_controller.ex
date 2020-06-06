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
    with {:ok, class} <- Class.validate_params(params) do
      id = class
           |> Builder.create_class()
           |> extract_id()
      json(conn, id)
    end
  end

  defp extract_id({:ok, %{new_class: %{id: id}}}) do
    %{class_id: id}
  end
end
