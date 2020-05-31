defmodule Helix.WebConsole.Api.PropertyView do
  use Helix.WebConsole, :view

  def render("index.json", %{properties: props}) do
    %{data: render_many(props, PropertyView, "property.json")}
  end

  def render("show.json", %{property: prop}) do
    %{data: render_one(prop, PropertyView, "property.json")}
  end

  def render("property.json", %{property: property}) do
    class = extract_class(property, :class)
    link_class = extract_class(property, :link_class)

    property
    |> Map.take([:id, :name, :type, :length, :precision, :scale, :nullable])
    |> Map.put(:class, class)
    |> Map.put(:link_class, link_class)
  end

  defp extract_class(property, field) do
    case Map.get(property, field) do
      nil -> nil
      class -> %{id: class.id, name: class.name}
    end
  end

end
