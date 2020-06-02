defmodule Helix.WebConsole.PropertyControllerTest do
  use Helix.WebConsole.ConnCase, async: true

  test "get properties", %{conn: conn} do
    conn = get(conn, "/api/properties")
    response = json_response(conn, 200)
    assert Enum.count(response) > 1
    first = hd(response)

    assert Map.keys(first) == [
             "class",
             "id",
             "length",
             "linked_class",
             "name",
             "nullable",
             "precision",
             "scale",
             "type"
           ]

    linked_prop = Enum.find(response, &(&1["linked_class"] != nil))

    %{
      "class" => %{"id" => class_id, "name" => "option"},
      "id" => prop_id,
      "length" => nil,
      "linked_class" => %{"id" => linked_class_id, "name" => "property"},
      "name" => "property",
      "nullable" => nil,
      "precision" => nil,
      "scale" => nil,
      "type" => type
    } = linked_prop

    assert class_id > 0
    assert prop_id > 0
    assert linked_class_id > 0
    refute linked_class_id == class_id
    assert type in ["single_link", "multiple_link"]
  end

  test "get property by id", %{conn: conn} do
    conn = get(conn, "/api/properties/1")
    response = json_response(conn, 200)

    %{
      "id" => 1,
      "name" => name,
      "type" => text
    } = response

    assert is_binary(name)
    assert is_binary(text)
  end

  test "get property by id returns 404", %{conn: conn} do
    conn = get(conn, "/api/properties/0")
    assert json_response(conn, 404) == "Not Found"
  end
end
