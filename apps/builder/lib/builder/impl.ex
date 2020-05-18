defmodule Helix.Builder.Impl do
  alias Helix.Builder.Repo
  alias Helix.Builder.{Class, ClassIdentifier, Property, ObjectMapping, SqlDefinition}
  alias Ecto.Multi

  import Ecto.Query, only: [from: 2]

  @class_class_id 1
  @property_class_id 2
  @sys_schema "sys"
  @public_schema "public"

  @moduledoc """
  Provides the functionality to create `Class` and `Property` elements with their underline sql objects
  """

  @class_attrs [:id, :name, :is_system]

  @doc """
  List all the classes in the system
  """
  @spec list_classes() :: [Class.t()]
  def list_classes() do
    query =
      from(Class,
        select: ^@class_attrs,
        order_by: :name
      )

    Repo.all(query)
  end

  @doc """
  Get the class with the given id
  """
  @spec get_class!(id :: integer()) :: Class.t()
  def get_class!(id) do
    query =
      from(c in Class,
        select: ^@class_attrs,
        where: c.id == ^id
      )

    Repo.one!(query)
  end

  def get_property!(id) do
    query =
      from([p, c, l] in properties(),
        where: p.id == ^id
      )

    Repo.one!(query)
  end

  def list_properties() do
    properties()
    |> Repo.all()
  end

  defp properties do
    from(p in Property,
      join: c in assoc(p, :class),
      left_join: l in assoc(p, :link_class),
      preload: [class: c, link_class: l]
    )
  end

  @doc """
  Creates a new `Class` and its related database table and columns
  """
  @spec create_class(Class.t()) :: {:ok, map()} | {:error, atom(), tuple()}
  def create_class(%Class{} = class) do
    Multi.new()
    |> Multi.insert(:new_class, Class.changeset(class))
    |> Multi.run(:sql_table, fn _repo, changes -> create_sql_table(changes) end)
    |> Multi.run(:table_mapping, fn _repo, changes -> insert_table_mapping(changes) end)
    |> Multi.run(:column_creation, fn _repo, changes -> create_columns(changes) end)
    |> Multi.run(:property_mapping, fn _repo, changes -> insert_property_mappings(changes) end)
    |> Repo.transaction()
    |> format_error()
  end

  @doc """
  Adds properties to a `Class` creating columns in the related sql table
  """
  @spec create_properties(ClassIdentifier.t(), [Property.t()]) ::
          {:ok, map()} | {:error, atom(), any()}
  def create_properties(%ClassIdentifier{} = class, properties) do
    Repo.transaction(fn ->
      class = Repo.get!(Class, class.id)
      sql_table = sql_table_for_class(class.id)

      with {:ok, created_props} = create_class_properties(class, properties),
           {:ok, column_creation} <-
             create_columns(%{
               new_class: %{class | properties: created_props},
               sql_table: sql_table
             }),
           {:ok, _} <-
             insert_property_mappings(%{column_creation: column_creation, sql_table: sql_table}) do
        {:ok, :success}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
    |> format_error()
  end

  defp create_sql_table(%{new_class: class}) do
    name = sqlify(class.name)
    schema = table_schema(class.is_system)
    ddl = SqlDefinition.ddl_for_table(schema, name)

    case execute_ddl(ddl) do
      {:ok, _} -> {:ok, {schema, name}}
      error -> error
    end
  end

  defp execute_ddl(ddl, opts \\ []) do
    meta = Ecto.Adapter.lookup_meta(Repo)

    try do
      # See ecto_sql/lib/ecto/adapters/postgres/connection.ex execute_ddl/1
      Repo.__adapter__().execute_ddl(meta, ddl, opts)
    rescue
      e -> {:error, e}
    end
  end

  defp create_class_properties(class, properties) do
    result =
      properties
      |> Enum.map(fn property ->
        property =
          Property.changeset(%Property{}, %{
            name: property.name,
            type: property.type,
            length: property.length,
            precision: property.precision,
            scale: property.scale,
            class_id: class.id,
            link_class_id: property.link_class_id
          })

        Repo.insert!(property)
      end)

    {:ok, result}
  end

  defp create_columns(%{new_class: class, sql_table: sql_table}) do
    Enum.reduce_while(class.properties, {:ok, []}, fn x, {_, acc} ->
      case create_column(sql_table, x) do
        {:ok, table_name, column} ->
          {:cont, {:ok, [{x.id, table_name, column} | acc]}}

        error ->
          {:halt, error}
      end
    end)
  end

  defp create_column(schema_table, property) do
    column_name = sqlify(property.name)

    {ddl, table, column} =
      cond do
        property.type in [:single_link, :multiple_link] ->
          related_table = sql_table_for_class(property.link_class_id)
          SqlDefinition.ddl_for_property(property, schema_table, column_name, related_table)

        property.type in [:single_option, :multiple_option] ->
          SqlDefinition.ddl_for_property(
            property,
            schema_table,
            column_name,
            {@sys_schema, "option"}
          )

        true ->
          SqlDefinition.ddl_for_property(property, schema_table, column_name, nil)
      end

    case execute_ddl(ddl) do
      {:ok, _} -> {:ok, table, column}
      error -> error
    end
  end

  defp insert_table_mapping(%{sql_table: {schema, name}, new_class: class}) do
    %ObjectMapping{
      id: class.id,
      class: @class_class_id,
      schema: schema,
      table: name
    }
    |> ObjectMapping.changeset()
    |> Repo.insert()
  end

  defp insert_property_mappings(%{column_creation: columns, sql_table: {schema, _}}) do
    columns
    |> Enum.each(fn {id, table, column} ->
      mapping =
        ObjectMapping.changeset(%ObjectMapping{
          id: id,
          class: @property_class_id,
          schema: schema,
          table: table,
          column: column
        })

      Repo.insert(mapping)
    end)

    {:ok, columns}
  end

  defp sql_table_for_class(id) when is_integer(id) do
    case Repo.get_by(ObjectMapping, id: id, class: @class_class_id) do
      nil -> raise ArgumentError, "The class with id #{id} does not exist"
      mapping -> {mapping.schema, mapping.table}
    end
  end

  defp sql_table_for_class(_id) do
    raise ArgumentError, "Illegal class id argument"
  end

  defp table_schema(true), do: @sys_schema
  defp table_schema(_), do: @public_schema

  defp sqlify(name) when is_binary(name) do
    name
    |> String.replace(~r/[^a-zA-Z0-9]/, "_")
    |> String.downcase()
  end

  defp format_error(
         {:error, :column_creation, %{postgres: %{code: :duplicate_column}} = error, _}
       ) do
    {:error, :duplicated_property, error}
  end

  defp format_error({:error, %{postgres: %{code: :duplicate_column}} = error}) do
    {:error, :duplicated_property, error}
  end

  defp format_error({:error, :new_class, error, _}) do
    {:error, :class_already_exist, error}
  end

  defp format_error(x), do: x
end
