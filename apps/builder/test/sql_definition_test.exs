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
          %Property{name: "a", type: :number},
          %Property{name: "b", type: :big_number},
          %Property{name: "c", type: :date},
          %Property{name: "d", type: :time},
          %Property{name: "e", type: :datetime},
          %Property{name: "f", type: :text, length: 100},
          %Property{name: "g", type: :big_text},
          %Property{name: "h", type: :decimal, precision: 8, scale: 2},
          %Property{name: "i", type: :yes_no},
          %Property{name: "j", type: :file},
          %Property{name: "k", type: :single_link, link_class_id: 1},
          %Property{name: "u", type: :single_option},
        ]
      }

      ddl = SqlDefinition.ddl_for_create(class)

      assert ddl == [
               {
                 :create,
                 %Table{name: "Class1", prefix: "public"},
                 [
                   {:add, :id, :serial, primary_key: true},
                   {:add, "a", :integer, []},
                   {:add, "b", :bigint, []},
                   {:add, "c", :date, []},
                   {:add, "d", :time, []},
                   {:add, "e", :timestamp, []},
                   {:add, "f", :string, [size: 100, null: nil]},
                   {:add, "g", :text, []},
                   {:add, "h", :numeric, [precision: 8, scale: 2, null: nil]},
                   {:add, "i", :boolean, []},
                   {:add, "j", :binary, []},
                   {:add, "k", :integer, []},
                   {:add, "u", :integer, []},
                 ]
               }
             ]
    end
  end
end
