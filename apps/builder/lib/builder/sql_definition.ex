defmodule Helix.Builder.SqlDefinition do
  alias Helix.Builder.Property
  alias Ecto.Migration.{Table, Reference}

  @moduledoc """
  Defines all the ddl statements to create objects in a sql database
  """

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
    ecto_type = to_ecto_type(property.type, property.length, property.precision, property.scale, property.nullable)
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
          {:add, column_name <> "_size", :bigint, []},
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
        %Table{name: "#{table}_#{column_name}" , prefix: schema},
        [
          {:add, :id, :serial, primary_key: true},
          {:add, table <> "_id", %Reference{table: table, prefix: schema, type: :integer}, []},
          {:add, :content, :binary, []},
          {:add, :name, :string, [size: 500]},
          {:add, :size, :bigint, []},
        ]
      },
      "#{table}_#{column_name}",
      nil
    }
  end
  #Defines the ddl statement to create single related type properties.
  defp ddl_for_column(property_type, {schema, table}, {related_schema, related_table}, column_name, {_, opts})
  when property_type in [:single_link, :single_select] do
    {
      {
        :alter,
        %Table{name: table, prefix: schema},
        [
          {:add, column_name, %Reference{table: related_table, prefix: related_schema, type: :integer}, opts}
        ]
      },
      table,
      column_name
    }
  end
  #Defines the ddl statement to create multiple related type properties.
  defp ddl_for_column(property_type, {schema, table}, {related_schema, related_table}, column_name, _)
  when property_type in [:multiple_link, :multiple_select] do
    {
      {
        :create,
        %Table{name: "#{table}_#{column_name}" , prefix: schema},
        [
          {:add, table <> "_id", %Reference{table: table, prefix: schema, type: :integer}, [primary_key: true]},
          {:add, related_table <> "_id", %Reference{table: related_table, prefix: related_schema, type: :integer}, [primary_key: true]},
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

  @ecto_mapping %{
    number: :integer,
    big_number: :bigint,
    date: :date,
    time: :time,
    datetime: :timestamp,
    big_text: :text,
    text: :string,
    file: :binary,
    yes_no: :boolean,
    single_link: :integer,
    single_select: :integer
  }
  @doc """
  Parses the atom representation of a data type to its ecto type representation

  ##Examples
  iex> Helix.Builder.SqlDefinition.to_ecto_type(:text, 200, nil, nil, false)
  {:string, [size: 200, null: false]}

  iex> Helix.Builder.SqlDefinition.to_ecto_type(:decimal, nil, 8, 2, nil)
  {:numeric, [precision: 8, scale: 2, null: nil]}

  iex> Helix.Builder.SqlDefinition.to_ecto_type(:number, nil, nil, nil, nil)
  {:integer, [null: nil]}

  """
  def to_ecto_type(:text, length, _p, _s, nullable) when is_integer(length) and length > 0 do
    {:string, [size: length, null: nullable]}
  end
  def to_ecto_type(:text, _l, _p, _s, _), do: raise ArgumentError, "invalid text length"
  def to_ecto_type(:decimal, _l, precision, scale, nullable)
    when is_integer(precision) and precision > 0 and is_integer(scale) and scale > 0 do
      {:numeric, [precision: precision, scale: scale, null: nullable] }
  end
  def to_ecto_type(:decimal, _l, _p, _s, _n), do: raise ArgumentError, "invalid decimal precision/scale"
  def to_ecto_type(value, _l, _p,  _s, nullable) when is_atom(value) do
    {@ecto_mapping[value], [null: nullable]}
  end
  def to_ecto_type(other, _, _, _, _), do: raise "an atom is expected, got #{inspect(other)}"

end
