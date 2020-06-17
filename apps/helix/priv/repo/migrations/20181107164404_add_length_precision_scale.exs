defmodule HX.Builder.Repo.Migrations.AddLengthPrecisionScale do
  use Ecto.Migration

  def change do
    alter table("property", prefix: "sys") do
      add :length, :smallint
      add :precision, :smallint
      add :scale, :smallint
    end
  end
end
