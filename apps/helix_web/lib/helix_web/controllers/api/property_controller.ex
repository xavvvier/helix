defmodule HXWeb.Api.PropertyController do
  use HXWeb, :controller

  alias HX

  action_fallback HXWeb.FallbackController

  def index(conn, _params) do
    properties = HX.list_properties()
    render(conn, "index.json", properties: properties)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, property} <- HX.get_property(id) do
      render(conn, "show.json", property: property)
    end
  end
end
