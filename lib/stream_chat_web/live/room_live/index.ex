defmodule StreamChatWeb.RoomLive.Index do
  use StreamChatWeb, :live_view
  alias StreamChat.Chat
  alias StreamChatWeb.RoomLive

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :index}} = socket) do
    {:noreply, assign_rooms(socket)}
  end

  def handle_params(%{"id" => id}, _uri, %{assigns: %{live_action: :show}} = socket) do
    {:noreply, socket
      |> assign_rooms()
      |> assign_room(id)}
  end

  def assign_rooms(socket) do
    assign(socket, :rooms, Chat.list_rooms)
  end

  def assign_room(socket, id) do
    assign(socket, :room, Chat.get_room!(id))
  end
end
