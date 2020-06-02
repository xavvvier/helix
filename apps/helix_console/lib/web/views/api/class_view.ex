defmodule Helix.WebConsole.Api.ClassView do
  use Helix.WebConsole, :view

  def render("index.json", %{classes: classes}) do
    render_many(classes, ClassView, "class.json")
  end

  def render("show.json", %{class: class}) do
    render_one(class, ClassView, "class.json")
  end

  def render("class.json", %{class: class}) do
    Map.take(class, [:id, :name, :is_system])
  end
end
