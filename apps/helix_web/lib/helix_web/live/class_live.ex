defmodule HXWeb.ClassLive do
  use HXWeb, :live_view
  alias HX.Builder.{Class, Property, PropertyType}
  alias HX.Builder

  defp default_property do
    %{name: "", type: :text, length: 200, precision: 4, scale: 20}
  end
  @impl true
  def mount(_params, _session, socket) do
    initial_property = default_property() |> Map.put(:name, "Name")
    socket =
      socket
      |> assign(
        changeset:
          Class.change_class(%{
            name: "",
            properties: [ initial_property ]
          })
      )
      |> assign(property_types: PropertyType.list_atom_types())
      |> assign(existing_classes: Enum.map(HX.list_classes(), &{&1.name, &1.id}))

    {:ok, socket }
  end

  @impl true
  def handle_event("add-property", _, socket) do
    new_property = default_property() |> Property.change_property()

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.update_change(:properties, fn props ->
        props ++ [new_property]
      end)

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("validate", %{"class" => params}, socket) do
    changeset =
      Class.change_class(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("create", %{"class" => params}, socket) do
    with {:ok, changeset} <- Builder.validate_class(params),
         {:ok, result} <- Builder.create_class(changeset) do
      {:noreply,
       socket
       |> put_flash(:info, "class created with id #{result.new_class.id}")
       |> redirect(to: Routes.class_path(HXWeb.Endpoint, :index))}
    else
      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

end
