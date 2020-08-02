defmodule HX.Builder.Property do
  use Ecto.Schema
  alias HX.Builder.{Class, Property, PropertyType}
  import Ecto.Changeset

  @typedoc """
    Type to represent the `Property` struct
  """
  @type t :: %__MODULE__{}

  @schema_prefix "sys"

  schema "property" do
    field(:name, :string)
    field(:type, PropertyType)
    field(:length, :integer)
    field(:precision, :integer)
    field(:scale, :integer)
    field(:nullable, :boolean, virtual: true)
    # what class the property belongs to
    belongs_to(:class, Class)
    # what class the link type (single_link, multiple_link) property points to
    belongs_to(:linked_class, Class)
  end

  def changeset(property, params \\ %{}) do
    property
    |> cast(params, [:class_id, :id, :name, :type, :length, :precision, :scale, :linked_class_id])
    |> cast_type()
    |> validate_length(:name, min: 1, max: 250)
    |> validate_links
    |> validate_text
    |> validate_decimal
  end

  defp cast_type(changeset) do
    type = get_field(changeset, :type)

    case is_atom(type) do
      true ->
        changeset

      false ->
        type_as_atom = PropertyType.parse_type(type)
        put_change(changeset, :type, type_as_atom)
    end
  end

  defp validate_decimal(changeset) do
    type = get_field(changeset, :type)

    case changeset.valid? and type == :decimal do
      true ->
        scale = get_field(changeset, :scale)
        precision = get_field(changeset, :precision)

        case is_integer(scale) and scale > 0 and is_integer(precision) and precision > 0 do
          true ->
            changeset

          _ ->
            add_error(changeset, :length, "Invalid precision/scale for decimal field")
        end

      _ ->
        changeset
    end
  end

  defp validate_text(changeset) do
    type = get_field(changeset, :type)

    case changeset.valid? and type == :text do
      true ->
        value = get_field(changeset, :length)

        case is_integer(value) and value > 0 do
          true ->
            changeset

          _ ->
            add_error(changeset, :length, "Invalid length for text field")
        end

      _ ->
        changeset
    end
  end

  defp validate_links(changeset) do
    type = get_field(changeset, :type)

    case changeset.valid? and type in [:single_link, :multiple_link] do
      true ->
        value = get_field(changeset, :linked_class_id)

        case is_integer(value) and value > 0 do
          true ->
            changeset

          _ ->
            add_error(changeset, :linked_class, "Invalid linked class id for #{type} field")
        end

      _ ->
        changeset
    end
  end

  @ecto_mapping %{
    number: :integer,
    big_number: :bigint,
    date: :date,
    time: :time,
    datetime: :timestamp,
    big_text: :text,
    text: :string,
    file: :string,
    yes_no: :boolean,
    single_link: :integer,
    single_option: :integer
  }

  @doc """
  Parses the atom representation of a data type to its ecto type representation

  ##Examples
  iex> HX.Builder.Property.ecto_type(%Property{type: :text, length: 200, nullable: false})
  {:string, [size: 200, null: false]}

  iex> HX.Builder.Property.ecto_type(%Property{type: :decimal, precision: 8, scale: 2})
  {:numeric, [precision: 8, scale: 2, null: nil]}

  iex> HX.Builder.Property.ecto_type(%Property{type: :number})
  {:integer, []}

  """
  def ecto_type(%Property{type: :text, length: length, nullable: nullable})
      when is_integer(length) and length > 0 do
    {:string, [size: length, null: nullable]}
  end

  def ecto_type(%Property{type: :text}), do: raise(ArgumentError, "invalid text length")

  def ecto_type(%Property{
        type: :decimal,
        precision: precision,
        scale: scale,
        nullable: nullable
      })
      when is_integer(precision) and precision > 0 and is_integer(scale) and scale > 0 do
    {:numeric, [precision: precision, scale: scale, null: nullable]}
  end

  def ecto_type(%Property{type: :decimal}),
    do: raise(ArgumentError, "invalid decimal precision/scale")

  def ecto_type(%Property{type: type, nullable: nil}) when is_atom(type) do
    {@ecto_mapping[type], []}
  end

  def ecto_type(%Property{type: type, nullable: nullable}) when is_atom(type) do
    {@ecto_mapping[type], [null: nullable]}
  end

  def ecto_type(%Property{type: other}),
    do: raise("an atom is expected, got #{inspect(other)}")
end
