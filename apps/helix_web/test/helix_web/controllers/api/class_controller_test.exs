defmodule HXWeb.Api.ClassControllerTest do
  use HXWeb.ConnCase, async: true

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
      conn =
        post(conn, "/api/classes", %{
          class: %{
            name: "",
            properties: []
          }
        })

      %{
        "name" => ["can't be blank"]
      } = json_response(conn, 500)
    end

    test "create class with no props successes", %{conn: conn} do
      conn =
        post(conn, "/api/classes", %{
          class: %{
            "name" => "test a",
            "properties" => []
          }
        })

      %{"class_id" => id} = json_response(conn, 200)
      assert id > 0
    end

    test "create class with invalid prop fails", %{conn: conn} do
      conn =
        post(conn, "/api/classes", %{
          class: %{
            "name" => "test b",
            "properties" => [
              %{"name" => "col a", "type" => "text"}
            ]
          }
        })

      response = json_response(conn, 500)
      assert response == %{"properties" => [%{"length" => ["Invalid length for text field"]}]}
    end

    test "create class with props successes", %{conn: conn} do
      conn =
        post(conn, "/api/classes", %{
          class: %{
            "name" => "test b",
            "properties" => [
              %{"name" => "col a", "type" => "text", length: 2},
              %{"name" => "col b", "type" => "datetime"}
            ]
          }
        })

      %{"class_id" => id} = json_response(conn, 200)
      assert id > 0
    end

    test "create class with duplicated name fails", %{conn: conn} do
      conn =
        post(conn, "/api/classes", %{
          class: %{
            "name" => "test c",
            "properties" => [
              %{"name" => "col a", "type" => "date"}
            ]
          }
        })

      %{"class_id" => id} = json_response(conn, 200)
      assert is_integer(id)

      conn =
        post(conn, "/api/classes", %{
          class: %{
            "name" => "test c",
            "properties" => [
              %{"name" => "col b", "type" => "datetime"}
            ]
          }
        })

      error = json_response(conn, 500)
      assert error == %{"unique_name" => ["has already been taken"]}
    end
  end
end
