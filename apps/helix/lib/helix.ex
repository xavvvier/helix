defmodule HX do
  @moduledoc """
  Gives access to all operations related to classes and properties
  """
  alias HX.Repo
  alias HX.Builder.{Class, Property}
  import Ecto.Query, only: [from: 2]

  @class_attrs [:id, :name, :is_system]

  @doc """
  Lists all the classes in the system
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
  Gets the class with the given id
  """
  @spec get_class(id :: integer()) :: Class.t()
  def get_class(id) do
    query =
      from(c in Class,
        select: ^@class_attrs,
        where: c.id == ^id
      )
    query |> Repo.one() |> tuple_response
  end

  defp tuple_response(nil), do: {:error, :not_found}
  defp tuple_response(object), do: {:ok, object}

  @doc """
  Gets the property with the given id
  """
  @spec get_property(id :: integer()) :: Property.t()
  def get_property(id) do
    query =
      from([p, c, l] in properties(),
        where: p.id == ^id
      )
    query |> Repo.one() |> tuple_response
  end

  @doc """
  Lists all the properties in the system
  """
  @spec list_properties() :: [Property.t()]
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
end
