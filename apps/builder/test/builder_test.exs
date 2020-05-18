defmodule Helix.Test.BuilderTest do
  use ExUnit.Case
  alias Helix.Builder.Test.SqlHelpers
  alias Helix.Builder.Repo
  alias Helix.Builder.{Class, ClassIdentifier, Property}
  alias Helix.Builder.Impl, as: Builder
  doctest Builder

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  test "create a new class" do
    class = %Class{name: "Class1", properties: []}
    {:ok, %{new_class: result_class}} = Builder.create_class(class)
    assert result_class.id > 0
  end

  test "create class with simple properties" do
    class = %Class{
      name: "Class2",
      properties: [
        %Property{name: "p1", type: :number},
        %Property{name: "p2", type: :text, length: 250},
        %Property{name: "p3\"--", type: :single_option}
      ]
    }

    {:ok, %{new_class: result_class}} = Builder.create_class(class)
    assert result_class.id > 0
    properties = SqlHelpers.class_properties(result_class.id)
    assert properties == [{"p1", :number}, {"p2", :text}, {"p3\"--", :single_option}]
  end

  test "creating a class creates a table" do
    invalid_name = "9[a*^B"
    valid_name = "9_a__b"
    {:ok, _} = Builder.create_class(%Class{name: invalid_name, properties: []})
    table = SqlHelpers.table_schema(valid_name)
    assert table == {"public", valid_name}
  end

  test "create class with properties creates table with columns" do
    class = %Class{
      name: "Class3",
      properties: [
        %Property{name: "p1", type: :number},
        %Property{name: "p2", type: :text, length: 250}
      ]
    }

    {:ok, %{new_class: result_class}} = Builder.create_class(class)
    assert result_class.id > 0
    properties = SqlHelpers.table_columns("public", "class3")

    assert properties == [
             {"id", "integer", nil, 32, 0},
             {"p1", "integer", nil, 32, 0},
             {"p2", "character varying", 250, nil, nil}
           ]
  end

  test "creating property name with id property fails" do
    class = %Class{
      name: "Class2",
      properties: [
        %Property{name: "id", type: :number}
      ]
    }

    {:error, :duplicated_property, _error} = Builder.create_class(class)
  end

  test "create a class with id property fails" do
    class = %Class{
      name: "Class4",
      properties: [
        %Property{name: "p1", type: :number},
        %Property{name: "p2$", type: :text, length: 250},
        %Property{name: "id", type: :text, length: 250}
      ]
    }

    {:error, :duplicated_property, _error} = Builder.create_class(class)
  end

  test "create a class fails in duplicated column name" do
    class = %Class{
      name: "Class4",
      properties: [
        %Property{name: "p1", type: :number},
        %Property{name: "p2$", type: :text, length: 250},
        %Property{name: "p2@", type: :text, length: 250}
      ]
    }

    {:error, :duplicated_property, _} = Builder.create_class(class)
  end

  test "create classes with different is_system passes" do
    {:ok, _result} = Builder.create_class(%Class{name: "ab", is_system: true, properties: []})
    {:ok, _result} = Builder.create_class(%Class{name: "ab", properties: []})
  end

  test "check class name after sqlifying" do
    {:ok, _result} = Builder.create_class(%Class{name: "a'b", properties: []})
    {:error, :sql_table, _, _} = Builder.create_class(%Class{name: "a%b", properties: []})
  end

  test "create a class with existing name fails" do
    {:ok, _result} = Builder.create_class(%Class{name: "ab", properties: []})
    {:error, :class_already_exist, _} = Builder.create_class(%Class{name: "ab", properties: []})
  end

  test "create class with is_system uses sys db prefix" do
    {:ok, %{sql_table: table_name}} =
      Builder.create_class(%Class{name: "ab", is_system: true, properties: []})

    assert table_name == {"sys", "ab"}
    schema = SqlHelpers.table_schema("ab")
    assert schema == {"sys", "ab"}
  end

  test "create class with not is_system uses public db prefix" do
    {:ok, %{sql_table: table_name}} =
      Builder.create_class(%Class{name: "ab", is_system: false, properties: []})

    assert table_name == {"public", "ab"}
    schema = SqlHelpers.table_schema("ab")
    assert schema == {"public", "ab"}
  end

  test "creating a class inserts object mapping for class" do
    {:ok, %{new_class: test_class}} =
      Builder.create_class(%Class{name: "test class", properties: []})

    mapping = SqlHelpers.class_mapping(test_class.id)
    assert mapping == {"public", "test_class", nil}
  end

  test "create column in system table" do
    {:ok, %{new_class: test_class}} =
      Builder.create_class(%Class{
        name: "test",
        is_system: true,
        properties: [
          %Property{name: "name", type: :text, length: 255}
        ]
      })

    props = [
      %Property{name: "p1", type: :number}
    ]

    {:ok, _} = Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)
    columns = SqlHelpers.table_columns("sys", "test")

    assert columns == [
             {"id", "integer", nil, 32, 0},
             {"name", "character varying", 255, nil, nil},
             {"p1", "integer", nil, 32, 0}
           ]
  end

  test "create similar property in class fails" do
    {:ok, %{new_class: test_class}} =
      Builder.create_class(%Class{
        name: "test",
        is_system: true,
        properties: [
          %Property{name: "na%me", type: :text, length: 250}
        ]
      })

    props = [
      %Property{name: "na$me", type: :number}
    ]

    {:error, :duplicated_property, _error} =
      Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)

    columns = SqlHelpers.table_columns("sys", "test")

    assert columns == [
             {"id", "integer", nil, 32, 0},
             {"na_me", "character varying", 250, nil, nil}
           ]
  end

  test "create column in non-system" do
    {:ok, %{new_class: test_class}} = Builder.create_class(%Class{name: "test", properties: []})

    props = [
      %Property{name: "p1", type: :number},
      %Property{name: "p4^", type: :text, length: 250}
    ]

    {:ok, _} = Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)
    columns = SqlHelpers.table_columns("public", "test")

    assert columns == [
             {"id", "integer", nil, 32, 0},
             {"p1", "integer", nil, 32, 0},
             {"p4_", "character varying", 250, nil, nil}
           ]
  end

  test "creating a class inserts object mapping for properties" do
    {:ok, %{new_class: tag_class}} = Builder.create_class(%Class{name: "tag", properties: []})

    {:ok, _} =
      Builder.create_class(%Class{
        name: "test class",
        is_system: true,
        properties: [
          %Property{name: "p%1", type: :number},
          %Property{name: "photo files", type: :multiple_file},
          %Property{name: "p4^", type: :text, length: 250},
          %Property{name: "one option", type: :single_option},
          %Property{name: "multiple option", type: :multiple_option},
          %Property{name: "single item", type: :single_link, link_class_id: tag_class.id},
          %Property{name: "multiple items", type: :multiple_link, link_class_id: tag_class.id}
        ]
      })

    mappings = SqlHelpers.property_mappings("sys", "test_class")

    assert mappings == [
             {"one option", "sys", "test_class", "one_option"},
             {"p4^", "sys", "test_class", "p4_"},
             {"p%1", "sys", "test_class", "p_1"},
             {"single item", "sys", "test_class", "single_item"}
           ]

    multiple_file_mapping = SqlHelpers.property_mappings("sys", "test_class_photo_files")
    assert multiple_file_mapping == [{"photo files", "sys", "test_class_photo_files", nil}]
    multiple_link_mapping = SqlHelpers.property_mappings("sys", "test_class_multiple_items")
    assert multiple_link_mapping == [{"multiple items", "sys", "test_class_multiple_items", nil}]
    multiple_option_mapping = SqlHelpers.property_mappings("sys", "test_class_multiple_option")

    assert multiple_option_mapping == [
             {"multiple option", "sys", "test_class_multiple_option", nil}
           ]
  end

  test "creating new properties inserts object mapping for properties" do
    {:ok, %{new_class: test_class}} =
      Builder.create_class(%Class{
        name: "test",
        properties: [
          %Property{name: "b", type: :text, length: 250}
        ]
      })

    props = [
      %Property{name: "a", type: :number}
    ]

    {:ok, _} = Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)
    mappings = SqlHelpers.property_mappings("public", "test")

    assert mappings == [
             {"a", "public", "test", "a"},
             {"b", "public", "test", "b"}
           ]
  end

  test "create class with all property data types at once" do
    props = [
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
      %Property{name: "y", type: :multiple_option}
    ]

    {:ok, _} = Builder.create_class(%Class{name: "test", properties: props})
    columns = SqlHelpers.table_columns("public", "test")

    assert columns == [
             {"a", "integer", nil, 32, 0},
             {"b", "bigint", nil, 64, 0},
             {"c", "date", nil, nil, nil},
             {"d", "time without time zone", nil, nil, nil},
             {"e", "timestamp without time zone", nil, nil, nil},
             {"f", "character varying", 100, nil, nil},
             {"g", "text", nil, nil, nil},
             {"h", "numeric", nil, 8, 2},
             {"i", "boolean", nil, nil, nil},
             {"id", "integer", nil, 32, 0},
             {"j", "bytea", nil, nil, nil},
             {"j_name", "character varying", 500, nil, nil},
             {"j_size", "bigint", nil, 64, 0},
             {"k", "integer", nil, 32, 0},
             {"u", "integer", nil, 32, 0}
           ]
  end

  test "create properties with all data types" do
    {:ok, %{new_class: test_class}} = Builder.create_class(%Class{name: "test", properties: []})

    props = [
      %Property{name: "a", type: :number},
      %Property{name: "b", type: :big_number},
      %Property{name: "c", type: :date},
      %Property{name: "d", type: :time},
      %Property{name: "e", type: :datetime},
      %Property{name: "f", type: :text, length: 100},
      %Property{name: "g", type: :big_text},
      %Property{name: "h", type: :decimal, precision: 8, scale: 2},
      %Property{name: "i", type: :yes_no},
      %Property{name: "j 5", type: :file},
      %Property{name: "k", type: :single_link, link_class_id: 1},
      %Property{name: "u", type: :single_option}
    ]

    {:ok, _} = Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)
    columns = SqlHelpers.table_columns("public", "test")

    assert columns == [
             {"a", "integer", nil, 32, 0},
             {"b", "bigint", nil, 64, 0},
             {"c", "date", nil, nil, nil},
             {"d", "time without time zone", nil, nil, nil},
             {"e", "timestamp without time zone", nil, nil, nil},
             {"f", "character varying", 100, nil, nil},
             {"g", "text", nil, nil, nil},
             {"h", "numeric", nil, 8, 2},
             {"i", "boolean", nil, nil, nil},
             {"id", "integer", nil, 32, 0},
             {"j_5", "bytea", nil, nil, nil},
             {"j_5_name", "character varying", 500, nil, nil},
             {"j_5_size", "bigint", nil, 64, 0},
             {"k", "integer", nil, 32, 0},
             {"u", "integer", nil, 32, 0}
           ]
  end

  test "test constraint creation in create_class" do
    props = [
      %Property{name: "parent class", type: :single_link, link_class_id: 1},
      %Property{name: "status type", type: :single_option}
    ]

    {:ok, %{new_class: _}} = Builder.create_class(%Class{name: "test", properties: props})
    fks = SqlHelpers.table_foreign_keys("public", "test")

    assert fks == [
             {"parent_class", "sys", "class", "id"},
             {"status_type", "sys", "option", "id"}
           ]
  end

  test "test constraint creation in create_properties" do
    {:ok, %{new_class: test_class}} = Builder.create_class(%Class{name: "test", properties: []})

    props = [
      %Property{name: "parent class", type: :single_link, link_class_id: 1},
      %Property{name: "status type", type: :single_option}
    ]

    {:ok, _} = Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)
    fks = SqlHelpers.table_foreign_keys("public", "test")

    assert fks == [
             {"parent_class", "sys", "class", "id"},
             {"status_type", "sys", "option", "id"}
           ]
  end

  test "creating class with multiple_file property creates additional table" do
    props = [
      %Property{name: "attachments", type: :multiple_file},
      %Property{name: "name", type: :text, length: 200}
    ]

    {:ok, %{new_class: _}} = Builder.create_class(%Class{name: "test", properties: props})
    columns = SqlHelpers.table_columns("public", "test")

    assert columns == [
             {"id", "integer", nil, 32, 0},
             {"name", "character varying", 200, nil, nil}
           ]

    columns = SqlHelpers.table_columns("public", "test_attachments")

    assert columns == [
             {"content", "bytea", nil, nil, nil},
             {"id", "integer", nil, 32, 0},
             {"name", "character varying", 500, nil, nil},
             {"size", "bigint", nil, 64, 0},
             {"test_id", "integer", nil, 32, 0}
           ]

    fks = SqlHelpers.table_foreign_keys("public", "test_attachments")

    assert fks == [
             {"test_id", "public", "test", "id"}
           ]
  end

  test "adding multiple_file property creates additional table" do
    {:ok, %{new_class: test_class}} = Builder.create_class(%Class{name: "person", properties: []})

    props = [
      %Property{name: "photos", type: :multiple_file},
      %Property{name: "name", type: :text, length: 200}
    ]

    {:ok, _} = Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)
    columns = SqlHelpers.table_columns("public", "person")

    assert columns == [
             {"id", "integer", nil, 32, 0},
             {"name", "character varying", 200, nil, nil}
           ]

    columns = SqlHelpers.table_columns("public", "person_photos")

    assert columns == [
             {"content", "bytea", nil, nil, nil},
             {"id", "integer", nil, 32, 0},
             {"name", "character varying", 500, nil, nil},
             {"person_id", "integer", nil, 32, 0},
             {"size", "bigint", nil, 64, 0}
           ]

    fks = SqlHelpers.table_foreign_keys("public", "person_photos")

    assert fks == [
             {"person_id", "public", "person", "id"}
           ]
  end

  test "creating class with multiple_link property creates additional table" do
    {:ok, %{new_class: tag_class}} = Builder.create_class(%Class{name: "tag", properties: []})

    props = [
      %Property{name: "tags", type: :multiple_link, link_class_id: tag_class.id},
      %Property{name: "name", type: :text, length: 200}
    ]

    {:ok, %{new_class: _}} = Builder.create_class(%Class{name: "test", properties: props})
    columns = SqlHelpers.table_columns("public", "test")

    assert columns == [
             {"id", "integer", nil, 32, 0},
             {"name", "character varying", 200, nil, nil}
           ]

    columns = SqlHelpers.table_columns("public", "test_tags")

    assert columns == [
             {"tag_id", "integer", nil, 32, 0},
             {"test_id", "integer", nil, 32, 0}
           ]

    fks = SqlHelpers.table_foreign_keys("public", "test_tags")

    assert fks == [
             {"tag_id", "public", "tag", "id"},
             {"test_id", "public", "test", "id"}
           ]
  end

  test "adding multiple_option property creates additional table" do
    {:ok, %{new_class: test_class}} = Builder.create_class(%Class{name: "a", properties: []})

    props = [
      %Property{name: "colors", type: :multiple_option},
      %Property{name: "name", type: :text, length: 100}
    ]

    {:ok, _} = Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)
    columns = SqlHelpers.table_columns("public", "a")

    assert columns == [
             {"id", "integer", nil, 32, 0},
             {"name", "character varying", 100, nil, nil}
           ]

    columns = SqlHelpers.table_columns("public", "a_colors")

    assert columns == [
             {"a_id", "integer", nil, 32, 0},
             {"option_id", "integer", nil, 32, 0}
           ]

    fks = SqlHelpers.table_foreign_keys("public", "a_colors")

    assert fks == [
             {"a_id", "public", "a", "id"},
             {"option_id", "sys", "option", "id"}
           ]
  end

  test "creating class with multiple_option property creates additional table" do
    props = [
      %Property{name: "colors", type: :multiple_option},
      %Property{name: "name", type: :text, length: 200}
    ]

    {:ok, %{new_class: _}} = Builder.create_class(%Class{name: "test", properties: props})
    columns = SqlHelpers.table_columns("public", "test")

    assert columns == [
             {"id", "integer", nil, 32, 0},
             {"name", "character varying", 200, nil, nil}
           ]

    columns = SqlHelpers.table_columns("public", "test_colors")

    assert columns == [
             {"option_id", "integer", nil, 32, 0},
             {"test_id", "integer", nil, 32, 0}
           ]

    fks = SqlHelpers.table_foreign_keys("public", "test_colors")

    assert fks == [
             {"option_id", "sys", "option", "id"},
             {"test_id", "public", "test", "id"}
           ]
  end
end
