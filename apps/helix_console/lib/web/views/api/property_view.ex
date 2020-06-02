defmodule Helix.WebConsole.Api.PropertyView do
  use Helix.WebConsole, :view

  def render("index.json", %{properties: props}) do
    render_many(props, PropertyView, "property.json")
  end

  def render("show.json", %{property: prop}) do
    render_one(prop, PropertyView, "property.json")
  end

  def render("property.json", %{property: property}) do
    class = extract_class(property, :class)
    linked_class = extract_class(property, :linked_class)

    property
    |> Map.take([:id, :name, :type, :length, :precision, :scale, :nullable])
    |> Map.put(:class, class)
    |> Map.put(:linked_class, linked_class)
  end

  defp extract_class(property, field) do
    case Map.get(property, field) do
      nil -> nil
      class -> %{id: class.id, name: class.name}
    end
  end
end
