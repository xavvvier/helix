defmodule Helix.Builder.Repo.Migrations.LinkProperties do
  use Ecto.Migration

  def change do
    alter table("property", prefix: "sys") do
      add :link_class_id, references(:class, type: :integer), null: true
    end

  end
end
