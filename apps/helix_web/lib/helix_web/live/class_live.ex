defmodule HXWeb.ClassLive do
  use HXWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "test", properties: [
      %{name: "a\"bc", type: :number}
    ])}
  end

  def handle_event("add-new-property", _, socket) do
    new_property = %{name: "def", type: :text}
    properties = socket.assigns.properties ++ [new_property]
    socket = assign(socket, properties: properties)
    {:noreply, socket}
  end

end
