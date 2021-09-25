defmodule HX.Builder do
  alias HX.Builder.{Class, ClassIdentifier, Property, SqlDefinition}
  import Ecto.Changeset, only: [apply_action: 2]
  alias Ecto.Multi
  alias HX.Repo


  @moduledoc """
  Context module grouping functionality related to `Class` and `Property` in the system
  """

  # TODO: add specs
  def validate_class(attrs \\ %{}) do
    Class.change_class(attrs)
    |> apply_action(:insert)
  end

  @doc """
  Creates a new `Class` and its related database table and columns
  Every `Class` creates an id `Property` by default.
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
  Add `Property` elements to an existent class, use the `ClassIdentifier` to locate the `Class`
  """
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
