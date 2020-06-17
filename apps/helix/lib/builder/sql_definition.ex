defmodule HX.Builder.SqlDefinition do
  alias HX.Builder.{Class, Property}
  alias Ecto.Migration.{Table, Reference}

  @moduledoc """
  Defines all the ddl statements to create objects in a sql database
  """

  def ddl_for_create(%Class{} = class) do
    {schema, table_name} = table_for_class(class)

    # Define the mandatory primary key column
    pk_column = {:add, :id, :serial, primary_key: true}

    [
      {
        :create,
        %Table{name: table_name, prefix: schema},
        [
          pk_column | ddl_create_props(class)
        ]
      }
      | ddl_create_complex_props(class)
    ]
  end

  def ddl_for_modify(%Class{} = class) do
    {schema, table_name} = table_for_class(class)

    [
      {
        :alter,
        %Table{name: table_name, prefix: schema},
        ddl_create_props(class)
      }
      | ddl_create_complex_props(class)
    ]
  end

  @sys_schema "sys"
  @public_schema "public"

  # Determines the sql schema and table name for a Class
  defp table_for_class(%Class{name: name, is_system: is_system}) do
    if is_system do
      {@sys_schema, name}
    else
      {@public_schema, name}
    end
  end

  @simple_props [
    :number,
    :big_number,
    :date,
    :time,
    :datetime,
    :big_text,
    :decimal,
    :text,
    :file,
    :yes_no,
    :single_link,
    :single_option
  ]

  defp ddl_create_props(%Class{} = class) do
    class.properties
    |> Enum.filter(&Enum.member?(@simple_props, &1.type))
    |> Enum.flat_map(&ddl_new_property/1)
  end

  # Defines the ddl statement to create a new property.
  defp ddl_new_property(%Property{type: :file, name: name}) do
    [
      {:add, name, :string, [size: 500]},
      {:add, name <> "_content", :binary, []},
      {:add, name <> "_size", :bigint, []}
    ]
  end

  defp ddl_new_property(%Property{name: name, type: type, linked_class: linked_class})
       when type in [:single_link, :single_option] do
    {ecto_type, opts} =
      case type do
        :single_link ->
          {schema, table_name} = table_for_class(linked_class)

          {
            %Reference{table: table_name, prefix: schema, type: :integer},
            []
          }

        :single_option ->
          {
            %Reference{table: "option", prefix: @sys_schema, type: :integer},
            []
          }
      end

    [
      {:add, name, ecto_type, opts}
    ]
  end

  defp ddl_new_property(%Property{} = prop) do
    {ecto_type, opts} = Property.ecto_type(prop)

    [
      {:add, prop.name, ecto_type, opts}
    ]
  end

  @complex_props [:multiple_file, :multiple_link, :multiple_option]

  # Determines the table :create operations for complex columns,
  # such as :multiple_file, :multiple_link, :multiple_option
  defp ddl_create_complex_props(%Class{} = class) do
    {schema, table_name} = table_for_class(class)

    class.properties
    |> Enum.filter(&Enum.member?(@complex_props, &1.type))
    |> Enum.map(&ddl_new_complex_property(&1, schema, table_name))
  end

  defp ddl_new_complex_property(%Property{type: :multiple_file, name: name}, schema, main_table) do
    {
      :create,
      %Table{name: "#{main_table}_#{name}", prefix: schema},
      [
        {:add, :id, :serial, primary_key: true},
        {:add, main_table <> "_id", %Reference{table: main_table, prefix: schema, type: :integer},
         []},
        {:add, :name, :string, [size: 500]},
        {:add, :content, :binary, []},
        {:add, :size, :bigint, []}
      ]
    }
  end

  defp ddl_new_complex_property(
         %Property{type: :multiple_link, name: name, linked_class: linked_class},
         schema,
         main_table
       ) do
    {related_schema, related_table} = table_for_class(linked_class)

    {
      :create,
      %Table{name: "#{main_table}_#{name}", prefix: schema},
      [
        {:add, main_table <> "_id", %Reference{table: main_table, prefix: schema, type: :integer},
         [primary_key: true]},
        {:add, related_table <> "_id",
         %Reference{table: related_table, prefix: related_schema, type: :integer},
         [primary_key: true]}
      ]
    }
  end

  defp ddl_new_complex_property(%Property{type: :multiple_option, name: name}, schema, main_table) do
    {
      :create,
      %Table{name: "#{main_table}_#{name}", prefix: schema},
      [
        {:add, main_table <> "_id", %Reference{table: main_table, prefix: schema, type: :integer},
         [primary_key: true]},
        {:add, "option_id", %Reference{table: "option", prefix: @sys_schema, type: :integer},
         [primary_key: true]}
      ]
    }
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
    ecto_type = Property.ecto_type(property)
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
       when property_type in [:single_link, :single_option] do
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
       when property_type in [:multiple_link, :multiple_option] do
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
