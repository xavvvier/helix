defmodule HXWeb.ClassLive do
  use HXWeb, :live_view
  alias HX.Builder.{Class, Property, PropertyType}

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
    new_property =
      %{name: "", type: :text}
      |> Property.change_property()

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.update_change(:properties, fn props ->
        props ++ [new_property]
      end)

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("validate", %{"class" => params}, socket) do
    new_property = %{name: "", type: :text}

    changeset =
      Class.change_class(params)
      |> Map.put(:action, :insert)

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end
end
