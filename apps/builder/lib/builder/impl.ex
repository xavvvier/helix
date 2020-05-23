defmodule Helix.Builder.Impl do
  alias Helix.Builder.Repo
  alias Helix.Builder.{Class, ClassIdentifier, Property, SqlDefinition}
  alias Ecto.Multi

  import Ecto.Query, only: [from: 2]

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
      left_join: l in assoc(p, :linked_class),
      preload: [class: c, linked_class: l]
    )
  end

  @doc """
  Creates a new `Class` and its related database table and columns
  """
  @spec create_class(Class.t()) :: {:ok, map()} | {:error, atom(), tuple()}
  def create_class(%Class{} = class) do
    class = %{class | properties: resolve_linked_properties(class.properties)}

    Multi.new()
    |> Multi.insert(:new_class, Class.changeset(class))
    |> Multi.run(:ddl_execution, fn _, %{new_class: class} ->
      SqlDefinition.ddl_for_create(class)
      |> execute_definitions()
    end)
    |> Repo.transaction()
    |> format_error()
  end

  @doc """
  Adds properties to a `Class` creating columns in the related sql table
  """
  @spec create_properties(ClassIdentifier.t(), [Property.t()]) ::
          {:ok, map()} | {:error, atom(), any()}
  def create_properties(%ClassIdentifier{id: id}, properties) do
    class = Repo.get!(Class, id)
    class = %{class | properties: resolve_linked_properties(properties)}

    Multi.new()
    |> Multi.run(:ddl_execution, fn _, _ ->
      SqlDefinition.ddl_for_modify(class)
      |> execute_definitions()
    end)
    |> Repo.transaction()
    |> format_error()
  end

  defp resolve_linked_properties(properties) do
    properties
    |> Enum.map(&resolve_link/1)
  end

  defp resolve_link(%Property{linked_class_id: id} = prop) when is_integer(id) and id > 0 do
    class = Repo.get!(Class, id)
    %{prop | linked_class: class}
  end

  defp resolve_link(prop), do: prop

  defp execute_definitions(definitions) do
    Enum.reduce_while(definitions, {:ok, nil}, fn ddl, _ ->
      case execute_ddl(ddl) do
        {:ok, _} ->
          {:cont, {:ok, definitions}}

        error ->
          {:halt, error}
      end
    end)
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

  defp format_error({:error, :ddl_execution, %{postgres: %{code: :duplicate_column}} = error, _}) do
    {:error, :duplicated_property, error}
  end

  defp format_error({:error, %{postgres: %{code: :duplicate_column}} = error}) do
    {:error, :duplicated_property, error}
  end

  defp format_error({:error, :new_class, error, _}) do
    {:error, :class_already_exists, error}
  end

  defp format_error(x), do: x
end
