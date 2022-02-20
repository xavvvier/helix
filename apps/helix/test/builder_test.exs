defmodule HX.Test.BuilderTest do
  use ExUnit.Case
  alias HX.Builder.Test.SqlHelpers
  alias HX.Repo
  alias HX.Builder
  alias HX.Builder.{Class, ClassIdentifier, Property}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  test "create a new class" do
    class = %Class{name: "Class1", properties: []}
    {:ok, %{new_class: result_class}} = Builder.create_class(class)
    assert result_class.id > 0
  end

  test "create class with illegal double quote in name" do
    class = %Class{
      name: "Class2",
      properties: [
        %Property{name: "p1", type: :number},
        %Property{name: "p3\"--", type: :single_option}
      ]
    }

    {:error, {:ddl_execution, %{message: message}}} = Builder.create_class(class)
    assert message =~ "bad field name"
  end

  test "creating a class creates a table" do
    {:ok, _} = Builder.create_class(%Class{name: "9[a*^B", properties: []})
    table = SqlHelpers.table_schema("9[a*^B")
    assert table == {"public", "9[a*^B"}
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
    properties = SqlHelpers.table_columns("public", "Class3")

    assert properties == [
             {"id", "integer", nil, 32, 0},
             {"p1", "integer", nil, 32, 0},
             {"p2", "character varying", 250, nil, nil}
           ]
  end

  test "class changeset validate internal props" do
    params = %{
      name: "Class2",
      properties: [
        %{name: "Name", type: :number},
        %{name: "Name", type: :number}
      ]
    }
    changeset = Class.changeset(%Class{}, params)
    refute changeset.valid?
  end

  test "creating property name with id property fails" do
    class = %Class{
      name: "Class2",
      properties: [
        %Property{name: "Name", type: :number},
        %Property{name: "Name", type: :number}
      ]
    }

    {:error, {:duplicated_property, reason}} = Builder.create_class(class)
    # reason should be a changeset
    reason
    |> IO.inspect(label: "reason")
  end

  test "create a class with id property fails" do
    changeset = Property.changeset(%Property{}, %{
      name: "id", type: :number
    })

    refute changeset.valid?

    class = %Class{
      name: "Class4",
      properties: [
        %Property{name: "p1", type: :number},
        %Property{name: "p2$", type: :text, length: 250},
        %Property{name: "id", type: :text, length: 250}
      ]
    }

    {:error, {:duplicated_property, error}} = Builder.create_class(class)
  end

  test "create classes with different is_system passes" do
    {:ok, _result} = Builder.create_class(%Class{name: "ab", is_system: true, properties: []})
    {:ok, _result} = Builder.create_class(%Class{name: "ab", properties: []})
  end

  test "check class name accept single quote" do
    {:ok, _result} = Builder.create_class(%Class{name: "a'b", properties: []})
    {:error, {:class_already_exists, _}} = Builder.create_class(%Class{name: "a'b", properties: []})
  end

  test "create a class with existing name fails" do
    {:ok, _result} = Builder.create_class(%Class{name: "ab", properties: []})
    {:error, {:class_already_exists, _}} = Builder.create_class(%Class{name: "ab", properties: []})
  end

  test "create class with is_system uses sys db prefix" do
    {:ok, _} = Builder.create_class(%Class{name: "ab", is_system: true, properties: []})
    schema = SqlHelpers.table_schema("ab")
    assert schema == {"sys", "ab"}
  end

  test "create class with not is_system uses public db prefix" do
    {:ok, _} = Builder.create_class(%Class{name: "ab", is_system: false, properties: []})
    schema = SqlHelpers.table_schema("ab")
    assert schema == {"public", "ab"}
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
             {"p4^", "character varying", 250, nil, nil}
           ]
  end

  test "create class with simple property data types at once" do
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
      %Property{name: "k", type: :single_link, linked_class_id: 1},
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
             {"j", "character varying", 500, nil, nil},
             {"j_content", "bytea", nil, nil, nil},
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
      %Property{name: "k", type: :single_link, linked_class_id: 1},
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
             {"j 5", "character varying", 500, nil, nil},
             {"j 5_content", "bytea", nil, nil, nil},
             {"j 5_size", "bigint", nil, 64, 0},
             {"k", "integer", nil, 32, 0},
             {"u", "integer", nil, 32, 0}
           ]
  end

  test "test constraint creation in create_class" do
    props = [
      %Property{name: "parent class", type: :single_link, linked_class_id: 1},
      %Property{name: "status type", type: :single_option}
    ]

    {:ok, %{new_class: _}} = Builder.create_class(%Class{name: "test", properties: props})
    fks = SqlHelpers.table_foreign_keys("public", "test")

    assert fks == [
             {"parent class", "sys", "class", "id"},
             {"status type", "sys", "option", "id"}
           ]
  end

  test "test constraint creation in create_properties" do
    {:ok, %{new_class: test_class}} = Builder.create_class(%Class{name: "test", properties: []})

    props = [
      %Property{name: "parent class", type: :single_link, linked_class_id: 1},
      %Property{name: "status type", type: :single_option}
    ]

    {:ok, _} = Builder.create_properties(%ClassIdentifier{id: test_class.id}, props)
    fks = SqlHelpers.table_foreign_keys("public", "test")

    assert fks == [
             {"parent class", "sys", "class", "id"},
             {"status type", "sys", "option", "id"}
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
      %Property{name: "tags", type: :multiple_link, linked_class_id: tag_class.id},
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
