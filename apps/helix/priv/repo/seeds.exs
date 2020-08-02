# Run as mix run priv/repo/seeds.exs
alias HX.Builder.{Class, Property}
alias HX.Builder
alias HX.Repo

for class <- [%{name: "class", id: 1}, %{name: "property", id: 2}] do
  if Repo.get_by(Class, name: class.name) == nil do
    Repo.insert!(%Class{name: class.name, id: class.id, is_system: true})
    Ecto.Adapters.SQL.query(Repo, "ALTER sequence sys.class_id_seq restart WITH 3")
  end
end

# insert form
form = %Class{
  name: "form",
  is_system: true,
  properties: [
    %Property{name: "name", type: :text, length: 200},
    %Property{name: "order", type: :number}
  ]
}

if Repo.get_by(Class, name: form.name) == nil do
  IO.inspect(Builder.create_class(form))
end

# insert tab
tab = %Class{
  name: "tab",
  is_system: true,
  properties: [
    %Property{name: "name", type: :text, length: 200},
    %Property{name: "url", type: :text, length: 200},
    %Property{name: "order", type: :number}
  ]
}

if Repo.get_by(Class, name: tab.name) == nil do
  IO.inspect(Builder.create_class(tab))
end

# insert view
view = %Class{
  name: "view",
  is_system: true,
  properties: [
    %Property{name: "name", type: :text, length: 200},
    %Property{name: "order", type: :number}
  ]
}

if Repo.get_by(Class, name: view.name) == nil do
  IO.inspect(Builder.create_class(view))
end

# insert otion class
view = %Class{
  name: "option",
  is_system: true,
  properties: [
    %Property{name: "property", type: :single_link, linked_class_id: 2, nullable: false},
    %Property{name: "code", type: :text, length: 5},
    %Property{name: "name", type: :text, length: 200},
    %Property{name: "order", type: :number},
    %Property{name: "color", type: :text, length: 10},
    %Property{name: "active", type: :yes_no}
  ]
}

if Repo.get_by(Class, name: view.name) == nil do
  IO.inspect(Builder.create_class(view))
end
