defmodule HX.Builder.Test.SqlHelpers do
  alias HX.Repo
  alias HX.Builder.Property

  import Ecto.Query, only: [from: 2]

  def class_properties(class_id) do
    properties_query =
      from(p in Property,
        where: p.class_id == ^class_id,
        order_by: fragment("lower(?)", p.name),
        select: {p.name, p.type}
      )

    Repo.all(properties_query)
  end

  def table_columns(schema, table) do
    query =
      from(c in "columns",
        where:
          c.table_schema == ^schema and
            c.table_name == ^table,
        order_by: c.column_name,
        select:
          {c.column_name, c.data_type, c.character_maximum_length, c.numeric_precision,
           c.numeric_scale}
      )

    query = %{query | prefix: "information_schema"}
    Repo.all(query)
  end

  def table_schema(table_name) do
    query =
      from(t in "tables",
        where:
          t.table_type == "BASE TABLE" and
            t.table_name == ^table_name,
        select: {t.table_schema, t.table_name}
      )

    query = %{query | prefix: "information_schema"}
    Repo.one(query)
  end

  def table_foreign_keys(schema, table) do
    query =
      from(tc in "table_constraints",
        join: kcu in "key_column_usage",
        on: tc.constraint_name == kcu.constraint_name and tc.table_schema == kcu.table_schema,
        join: ccu in "constraint_column_usage",
        on: ccu.constraint_name == tc.constraint_name,
        where:
          tc.constraint_type == "FOREIGN KEY" and
            tc.table_schema == ^schema and
            tc.table_name == ^table,
        select: {kcu.column_name, ccu.table_schema, ccu.table_name, ccu.column_name},
        order_by: kcu.column_name
      )

    query = %{query | prefix: "information_schema"}
    Repo.all(query)
  end
end
