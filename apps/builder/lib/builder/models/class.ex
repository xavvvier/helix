defmodule Helix.Builder.Class do
  use Ecto.Schema
  alias Helix.Builder.Class
  import Ecto.Changeset

  @typedoc """
    Type to represent the `Class` struct
  """
  @type t :: %__MODULE__{}

  @schema_prefix "sys"
  schema "class" do
    field(:name, :string)
    field(:is_system, :boolean, default: false)
    has_many(:properties, Helix.Builder.Property)
  end

  def changeset(class, params \\ %{}) do
    class
    |> cast(params, [:id, :name, :is_system])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 250)
    |> unique_constraint(:unique_name, name: :table_name_is_system_index)
    |> cast_assoc(:properties)
  end

  def validate_params(params) do
    %Class{}
    |> changeset(params)
    |> apply_action(:insert)
  end
end
