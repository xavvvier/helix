# Run as mix run priv/repo/seeds.exs
alias Helix.Builder.{Class, Property}
alias Helix.Builder
alias Helix.Builder.Repo

for class <- [%{name: "class", id: 1}, %{name: "croperty", id: 2}] do
  if Repo.get_by(Class, name: class.name) == nil do
    Repo.insert!(%Class{name: class.name, id: class.id, is_system: :true})
    Ecto.Adapters.SQL.query(Repo, "ALTER sequence sys.class_id_seq restart WITH 3")
  end
end

#insert form
form = %Class{
  name: "Form",
  is_system: :true,
  properties: [
    %Property{name: "Name", type: :text, length: 200},
    %Property{name: "Order", type: :number}
  ]
}
if Repo.get_by(Class, name: form.name) == nil do
  IO.inspect Builder.create_class(form)
end

#insert tab
tab = %Class{
  name: "Tab",
  is_system: :true,
  properties: [
    %Property{name: "Name", type: :text, length: 200},
    %Property{name: "Url", type: :text, length: 200},
    %Property{name: "Order", type: :number}
  ]
}
if Repo.get_by(Class, name: tab.name) == nil do
  IO.inspect Builder.create_class(tab)
end

#insert view
view = %Class{
  name: "View",
  is_system: :true,
  properties: [
    %Property{name: "Name", type: :text, length: 200},
    %Property{name: "Order", type: :number},
  ]
}
if Repo.get_by(Class, name: view.name) == nil do
  IO.inspect Builder.create_class(view)
end

#insert otion class
view = %Class{
  name: "Option",
  is_system: :true,
  properties: [
    %Property{name: "Property", type: :single_link, link_class_id: 2, nullable: false},
    %Property{name: "Code", type: :text, length: 5},
    %Property{name: "Name", type: :text, length: 200},
    %Property{name: "Order", type: :number},
    %Property{name: "Color", type: :text, length: 10},
    %Property{name: "Active", type: :yes_no},
  ]
}
if Repo.get_by(Class, name: view.name) == nil do
  IO.inspect Builder.create_class(view)
end
