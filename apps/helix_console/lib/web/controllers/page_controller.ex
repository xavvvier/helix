defmodule Helix.WebConsole.PageController do
  use Helix.WebConsole, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
