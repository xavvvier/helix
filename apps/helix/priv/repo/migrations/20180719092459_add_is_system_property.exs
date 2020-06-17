defmodule HX.Builder.Repo.Migrations.AddIsSystemProperty do
  use Ecto.Migration
  @schema_prefix "sys"

  def change do
    alter table("class", prefix: @schema_prefix) do
      add :is_system, :boolean
    end
    create unique_index(:class, 
                        [:name, :is_system], 
                        prefix: @schema_prefix,
                        name: :table_name_is_system_index)
  end
end
