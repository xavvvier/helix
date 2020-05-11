defmodule Helix.Builder.ObjectMapping do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "sys"
  schema "object_mapping" do
    field :schema, :string
    field :class, :integer
    field :table, :string
    field :column, :string
  end

  def changeset(mapping, params \\ %{}) do
    mapping
    |> cast(params, [:id, :class, :schema, :table, :column])
  end
end
