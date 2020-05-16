defmodule Helix.Test.SqlDefinitionTest do
  use ExUnit.Case, async: true
  alias Helix.Builder.SqlDefinition
  alias Helix.Builder.{Class, Property}
  alias Ecto.Migration.{Table}
  doctest Helix.Builder.SqlDefinition

  describe "ddl_for_create" do
    @tag single: true
    test "ddl_for_create with no properties" do
      class = %Class{name: "Class1", properties: []}
      ddl = SqlDefinition.ddl_for_create(class)

      assert ddl == [
               {
                 :create,
                 %Table{name: "Class1", prefix: "public"},
                 [
                   {:add, :id, :serial, primary_key: true}
                 ]
               }
             ]
    end

    @tag single: true
    test "ddl_for_create with properties" do
      class = %Class{
        name: "Class1",
        properties: [
          %Property{name: "p1", type: :number},
          %Property{name: "p2", type: :text, length: 250}
        ]
      }

      ddl = SqlDefinition.ddl_for_create(class)

      assert ddl == [
               {
                 :create,
                 %Table{name: "Class1", prefix: "public"},
                 [
                   {:add, :id, :serial, primary_key: true},
                   {:add, "p1", {:integer, [null: nil]}, []},
                   {:add, "p2", {:string, [size: 250, null: nil]}, []}
                 ]
               }
             ]
    end
  end
end
