defmodule Helix.Builder.Repo.Migrations.AddObjectMapping do
  use Ecto.Migration

  def change do
    create table("object_mapping", prefix: "sys", primary_key: false) do
      add :id, :integer, primary_key: true
      add :class, :integer, primary_key: true
      add :schema, :string, size: 250 , null: false
      add :table, :string, size: 250, null: false
      add :column, :string, size: 250
    end
  end
end
