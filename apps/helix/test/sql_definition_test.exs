defmodule HX.Test.SqlDefinitionTest do
  use ExUnit.Case, async: true
  alias HX.Builder.SqlDefinition
  alias HX.Builder.{Class, Property}
  alias Ecto.Migration.{Table, Reference}
  doctest HX.Builder.SqlDefinition

  describe "ddl_for_create" do
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

    test "ddl_for_create with properties" do
      class = %Class{
        name: "class1",
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
          %Property{name: "k", type: :single_link, linked_class: %Class{name: "kellogs"}},
          %Property{name: "u", type: :single_option}
        ]
      }

      ddl = SqlDefinition.ddl_for_create(class)

      assert ddl == [
               {
                 :create,
                 %Table{name: "class1", prefix: "public"},
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
                   {:add, "j", :string, [size: 500]},
                   {:add, "j_content", :binary, []},
                   {:add, "j_size", :bigint, []},
                   {:add, "k", %Reference{table: "kellogs", prefix: "public", type: :integer},
                    []},
                   {:add, "u", %Reference{table: "option", prefix: "sys", type: :integer}, []}
                 ]
               }
             ]
    end

    test "ddl_for_create with complex properties" do
      class = %Class{
        name: "complex",
        properties: [
          %Property{name: "regular field", type: :text, length: 430, nullable: false},
          %Property{name: "attachments", type: :multiple_file},
          %Property{name: "team", type: :multiple_link, linked_class: %Class{name: "Player"}},
          %Property{name: "colors", type: :multiple_option}
        ]
      }

      ddl = SqlDefinition.ddl_for_create(class)

      assert ddl == [
               {
                 :create,
                 %Table{name: "complex", prefix: "public"},
                 [
                   {:add, :id, :serial, primary_key: true},
                   {:add, "regular field", :string, [size: 430, null: false]}
                 ]
               },
               {
                 :create,
                 %Table{name: "complex_attachments", prefix: "public"},
                 [
                   {:add, :id, :serial, primary_key: true},
                   {:add, "complex_id",
                    %Reference{table: "complex", prefix: "public", type: :integer}, []},
                   {:add, :name, :string, [size: 500]},
                   {:add, :content, :binary, []},
                   {:add, :size, :bigint, []}
                 ]
               },
               {
                 :create,
                 %Table{name: "complex_team", prefix: "public"},
                 [
                   {:add, "complex_id",
                    %Reference{table: "complex", prefix: "public", type: :integer},
                    [primary_key: true]},
                   {:add, "Player_id",
                    %Reference{table: "Player", prefix: "public", type: :integer},
                    [primary_key: true]}
                 ]
               },
               {
                 :create,
                 %Table{name: "complex_colors", prefix: "public"},
                 [
                   {:add, "complex_id",
                    %Reference{table: "complex", prefix: "public", type: :integer},
                    [primary_key: true]},
                   {:add, "option_id", %Reference{table: "option", prefix: "sys", type: :integer},
                    [primary_key: true]}
                 ]
               }
             ]
    end
  end
end
