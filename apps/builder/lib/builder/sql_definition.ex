defmodule Helix.Builder.SqlDefinition do
  alias Helix.Builder.{Class, Property}
  alias Ecto.Migration.{Table, Reference}

  @moduledoc """
  Defines all the ddl statements to create objects in a sql database
  """

  def ddl_for_create(%Class{} = class) do
    name = class.name
    schema = if class.is_system, do: "sys", else: "public"

    # Define the mandatory primary key column
    pk_column = {:add, :id, :serial, primary_key: true}

    # Determine the table :create operations for complex columns (:file, :multiple_file, :multiple_link, :multiple_select)
    extra_table_for_complex_properties = []

    [
      {
        :create,
        %Table{name: name, prefix: schema},
        [
          pk_column | ddl_create_props(class)
        ]
      }
      | extra_table_for_complex_properties
    ]
  end

  defp ddl_create_props(%Class{} = class) do
    class.properties
    |> Enum.map(fn prop ->
      ddl_new_property(prop)
    end)
  end

  # Defines the ddl statement to create a new property.
  defp ddl_new_property(prop) do
    ecto_type = Property.to_ecto_type(prop)
    {:add, prop.name, ecto_type, []}
  end

  @doc """
  Defines the ddl statement to create a sql table with a serial id column
  """
  def ddl_for_table(schema, name) do
    {
      :create,
      %Table{name: name, prefix: schema},
      [
        {:add, :id, :serial, primary_key: true}
      ]
    }
  end

  @doc """
  Defines the ddl statement to create a column for the given property
  """
  def ddl_for_property(%Property{} = property, schema_table, column_name, related_schema) do
    ecto_type = Property.to_ecto_type(property)
    ddl_for_column(property.type, schema_table, related_schema, column_name, ecto_type)
  end

  defp ddl_for_column(:file, {schema, table}, _, column_name, {ecto_type, opts}) do
    {
      {
        :alter,
        %Table{name: table, prefix: schema},
        [
          {:add, column_name, ecto_type, opts},
          {:add, column_name <> "_name", :string, [size: 500]},
          {:add, column_name <> "_size", :bigint, []}
        ]
      },
      table,
      column_name
    }
  end

  defp ddl_for_column(:multiple_file, {schema, table}, _, column_name, _) do
    {
      {
        :create,
        %Table{name: "#{table}_#{column_name}", prefix: schema},
        [
          {:add, :id, :serial, primary_key: true},
          {:add, table <> "_id", %Reference{table: table, prefix: schema, type: :integer}, []},
          {:add, :content, :binary, []},
          {:add, :name, :string, [size: 500]},
          {:add, :size, :bigint, []}
        ]
      },
      "#{table}_#{column_name}",
      nil
    }
  end

  # Defines the ddl statement to create single related type properties.
  defp ddl_for_column(
         property_type,
         {schema, table},
         {related_schema, related_table},
         column_name,
         {_, opts}
       )
       when property_type in [:single_link, :single_select] do
    {
      {
        :alter,
        %Table{name: table, prefix: schema},
        [
          {:add, column_name,
           %Reference{table: related_table, prefix: related_schema, type: :integer}, opts}
        ]
      },
      table,
      column_name
    }
  end

  # Defines the ddl statement to create multiple related type properties.
  defp ddl_for_column(
         property_type,
         {schema, table},
         {related_schema, related_table},
         column_name,
         _
       )
       when property_type in [:multiple_link, :multiple_select] do
    {
      {
        :create,
        %Table{name: "#{table}_#{column_name}", prefix: schema},
        [
          {:add, table <> "_id", %Reference{table: table, prefix: schema, type: :integer},
           [primary_key: true]},
          {:add, related_table <> "_id",
           %Reference{table: related_table, prefix: related_schema, type: :integer},
           [primary_key: true]}
        ]
      },
      "#{table}_#{column_name}",
      nil
    }
  end

  # Defines the ddl statement to create a column for a property.
  defp ddl_for_column(_, {schema, table}, _, column_name, {ecto_type, opts}) do
    {
      {
        :alter,
        %Table{name: table, prefix: schema},
        [
          {:add, column_name, ecto_type, opts}
        ]
      },
      table,
      column_name
    }
  end
end
