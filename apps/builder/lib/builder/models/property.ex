defmodule Helix.Builder.Property do
  use Ecto.Schema
  alias Helix.Builder.{Property, PropertyType}
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
    belongs_to(:class, Helix.Builder.Class)
    # what class the link type (single_link, multiple_link) property points to
    belongs_to(:link_class, Helix.Builder.Class)
  end

  def changeset(property, params \\ %{}) do
    property
    |> cast(params, [:class_id, :id, :name, :type, :length, :precision, :scale, :link_class_id])
    |> validate_length(:name, min: 1, max: 250)
    |> validate_links
    |> validate_text
    |> validate_decimal
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
        value = get_field(changeset, :link_class_id)

        case is_integer(value) and value > 0 do
          true ->
            changeset

          _ ->
            add_error(changeset, :link_class, "Invalid link class id for #{type} field")
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
    file: :binary,
    yes_no: :boolean,
    single_link: :integer,
    single_select: :integer
  }

  @doc """
  Parses the atom representation of a data type to its ecto type representation

  ##Examples
  iex> Helix.Builder.Property.ecto_type(%Property{type: :text, length: 200, nullable: false})
  {:string, [size: 200, null: false]}

  iex> Helix.Builder.Property.ecto_type(%Property{type: :decimal, precision: 8, scale: 2})
  {:numeric, [precision: 8, scale: 2, null: nil]}

  iex> Helix.Builder.Property.ecto_type(%Property{type: :number})
  {:integer, [null: nil]}

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

  def ecto_type(%Property{type: type, nullable: nullable}) when is_atom(type) do
    {@ecto_mapping[type], [null: nullable]}
  end

  def ecto_type(%Property{type: other}),
    do: raise("an atom is expected, got #{inspect(other)}")
end
