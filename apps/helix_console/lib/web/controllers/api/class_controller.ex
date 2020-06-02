defmodule Helix.WebConsole.Api.ClassController do
  use Helix.WebConsole, :controller

  alias Helix.Builder.Query

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
end
