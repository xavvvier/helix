defmodule HX.Repo.Migrations.AddPropertyNameUniqueConstraint do
  use Ecto.Migration
  @schema_prefix "sys"

  def change do
    create unique_index(
             :property,
             [:name, :class_id],
             prefix: @schema_prefix,
             name: :property_name_unique_index
           )
  end
end
