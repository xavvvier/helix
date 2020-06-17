defmodule HXWeb.Api.PropertyController do
  use HXWeb, :controller

  alias HX.Builder.Query

  action_fallback HXWeb.FallbackController

  def index(conn, _params) do
    properties = Query.list_properties()
    render(conn, "index.json", properties: properties)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, property} <- Query.get_property(id) do
      render(conn, "show.json", property: property)
    end
  end
end
