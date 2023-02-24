defmodule StreamChatWeb.ChatLive.Root do
  use StreamChatWeb, :live_view
  alias StreamChat.Chat
  alias StreamChatWeb.Endpoint
  alias StreamChatWeb.ChatLive.Room

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :index}} = socket) do
    {:noreply, assign_rooms(socket)}
  end

  def handle_params(%{"id" => id}, _uri, %{assigns: %{live_action: :show}} = socket) do
    if connected?(socket), do: Endpoint.subscribe("room:#{id}")

    {:noreply,
     socket
     |> assign_rooms()
     |> assign_active_room(id)
     |> assign_active_room_messages()}
  end

  def assign_active_room_messages(socket) do
    stream(socket, :messages, Chat.messages_for(socket.assigns.room.id))
  end

  def insert_new_message(socket, message) do
    socket
    |> stream_insert(:messages, Chat.preload_message_sender(message), at: 0)
  end

  def handle_info(%{event: "new_message", payload: %{message: message}}, socket) do
    {:noreply,
     socket
     |> insert_new_message(message)}
  end

  def assign_rooms(socket) do
    assign(socket, :rooms, Chat.list_rooms())
  end

  def assign_active_room(socket, id) do
    assign(socket, :room, Chat.get_room!(id))
  end
end
