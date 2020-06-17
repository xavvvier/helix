defmodule HX.Builder.Repo.Migrations.AddClassTable do
  use Ecto.Migration
  @schema_prefix "sys"

  def change do
    execute "CREATE SCHEMA sys", "DROP SCHEMA sys"
    create table("class", prefix: @schema_prefix, primary_key: false) do
      add :id, :serial, primary_key: true
      add :name, :string, size: 250
    end
    create table("property", prefix: @schema_prefix, primary_key: false) do
      add :id, :serial, primary_key: true
      add :name, :string, size: 250
      add :type, :smallint, null: false
      add :class_id, references(:class, type: :integer), null: false
    end
  end
end
