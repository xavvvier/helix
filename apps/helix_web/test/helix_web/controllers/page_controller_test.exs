defmodule HXWeb.PageControllerTest do
  use HXWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Everything starts here"
  end
end
