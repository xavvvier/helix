defmodule Helix.WebConsole.Api.ClassControllerTest do
  use Helix.WebConsole.ConnCase, async: true

  test "getting classes", %{conn: conn} do
    conn = get(conn, "/api/classes")

    assert json_response(conn, 200) ==
             [
               %{"id" => 1, "is_system" => true, "name" => "class"},
               %{"id" => 3, "is_system" => true, "name" => "form"},
               %{"id" => 6, "is_system" => true, "name" => "option"},
               %{"id" => 2, "is_system" => true, "name" => "property"},
               %{"id" => 4, "is_system" => true, "name" => "tab"},
               %{"id" => 5, "is_system" => true, "name" => "view"}
             ]
  end

  test "get class by id", %{conn: conn} do
    conn = get(conn, "/api/classes/1")
    assert json_response(conn, 200) == %{"id" => 1, "is_system" => true, "name" => "class"}
  end

  test "get class by id returns 404", %{conn: conn} do
    conn = get(conn, "/api/classes/0")
    assert json_response(conn, 404) == "Not Found"
  end
end
