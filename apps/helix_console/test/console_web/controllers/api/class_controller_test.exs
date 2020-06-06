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

  describe "class creation" do

    test "create class with no name fails", %{conn: conn} do
      conn = post(conn, "/api/classes", %{
        class: %{
          name: "",
          properties: []
        }
      })
      [%{
        "details" => %{"validation" => "required"},
        "field" => "name",
        "message" => "can't be blank"
      }] = json_response(conn, 500)
    end

    test "create class with no props successes", %{conn: conn} do
      conn = post(conn, "/api/classes", %{
        class: %{
          "name" => "test a",
          "properties" => []
        }
      })
      %{"class_id" => id} = json_response(conn, 200)
      assert id > 0
    end

  end

end
