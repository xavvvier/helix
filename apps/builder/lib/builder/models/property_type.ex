defmodule Helix.Builder.PropertyType do
  @behaviour Ecto.Type

  def type, do: :smallint

  def cast(value), do: {:ok, value}

  def load(value), do: {:ok, to_atom(value)}

  def dump(value), do: {:ok, to_integer(value)}

  def embed_as(_format), do: :dump

  def equal?(type1, type2), do: type1 == type2

  # Defines how the property type is going to be stored in the database
  @mapping %{
    number: 1,
    big_number: 2,
    date: 3,
    time: 4,
    datetime: 5,
    text: 6,
    big_text: 7,
    decimal: 8,
    yes_no: 9,
    file: 10,
    multiple_file: 11,
    single_link: 12,
    multiple_link: 13,
    single_option: 14,
    multiple_option: 15
  }

  @doc """
  List all the property types
  """
  def list_types() do
    Enum.to_list(@mapping)
  end

  @doc """
  Parses the atom representation of a data type to its integer representation in the database.

  ##Examples
    iex> Helix.Builder.PropertyType.to_integer(:text)
    6
    iex> Helix.Builder.PropertyType.to_integer("text")
    6
  """
  def to_integer(atom) when is_atom(atom) do
    if atom in Map.keys(@mapping) do
      @mapping[atom]
    else
      raise ArgumentError, message: "Illegal property type: #{atom}"
    end
  end

  def to_integer(str) when is_binary(str) do
    String.to_existing_atom(str)
    |> to_integer()
  end

  def to_integer(non_atom), do: raise("an atom is expected, got #{inspect(non_atom)}")

  @doc """
  Parses the integer representation of a data type to is atom representation

  ##Example
    iex> Helix.Builder.PropertyType.to_atom(6)
    :text

  """
  def to_atom(value) when is_integer(value) do
    case Enum.find(@mapping, fn {_k, v} -> v == value end) do
      {atom, _value} -> atom
      nil -> raise "undefined type"
    end
  end

  def to_atom(_), do: raise("an integer is expected")

  def parse_type(type) when is_binary(type) do
    String.to_existing_atom(type)
  end
  def parse_type(type) when is_atom(type), do: type
end
