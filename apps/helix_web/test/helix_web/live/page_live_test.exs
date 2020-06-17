defmodule HXWeb.PageLiveTest do
  use HXWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/live")
    assert disconnected_html =~ "Welcome to Helix!"
    assert render(page_live) =~ "Welcome to Helix!"
  end
end
