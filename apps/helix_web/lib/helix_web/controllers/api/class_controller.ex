defmodule HXWeb.Api.ClassController do
  use HXWeb, :controller

  alias HX.Builder.Class
  alias HX.Builder.Impl, as: Builder

  action_fallback HXWeb.FallbackController

  def index(conn, _params) do
    classes = HX.list_classes()
    render(conn, "index.json", classes: classes)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, class} <- HX.get_class(id) do
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
