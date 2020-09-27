defmodule HXWeb.ClassLive do
  use HXWeb, :live_view
  alias HX.Builder.{Class, PropertyType}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        changeset:
          Class.change_class(%{
            name: "",
            properties: [
              %{name: "Name", type: :text}
            ]
          })
      )
      |> assign(property_types: PropertyType.list_atom_types())

    {:ok, socket}
  end

  @impl true
  def handle_event("add-property", _, socket) do
    new_property = %{name: "", type: :text}
    class = socket.assigns.class
    properties = class.properties ++ [new_property]
    socket = assign(socket, class: %{class | properties: properties})
    {:noreply, socket}
  end
end
