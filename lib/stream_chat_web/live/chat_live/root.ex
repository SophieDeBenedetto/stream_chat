defmodule StreamChatWeb.ChatLive.Root do
  use StreamChatWeb, :live_view
  alias StreamChat.Chat
  alias StreamChatWeb.Endpoint
  alias StreamChatWeb.ChatLive.{Rooms, Room}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_active_room()
     |> assign_scrolled_to_top("false")}
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

  def handle_info(%{event: "new_message", payload: %{message: message}}, socket) do
    {:noreply,
     socket
     |> insert_new_message(message)}
  end

  def handle_event("load_more", _params, socket) do
    {:noreply,
    socket
    |> insert_previous_five_messages()
    |> assign_scrolled_to_top("true")}
  end

  def handle_event("unpin_scrollbar_from_top", _params, socket) do
    {:noreply,
    socket
    |> assign_scrolled_to_top("false")}
  end

  def insert_new_message(socket, message) do
    socket
    |> stream_insert(:messages, Chat.preload_message_sender(message))
  end

  def insert_previous_five_messages(socket) do
    Enum.reduce(Chat.get_previous_n_messages(socket.assigns.oldest_message_id, 5), socket, fn message, socket ->
      stream_insert(socket, :messages, Chat.preload_message_sender(message), at: 0)
      |> assign(:oldest_message_id, message.id)
    end)
  end

  def assign_active_room_messages(socket) do
    messages = Chat.messages_for(socket.assigns.room.id)
    socket
    |> stream(:messages, messages)
    |> assign(:oldest_message_id, List.first(messages).id)
  end

  def assign_rooms(socket) do
    assign(socket, :rooms, Chat.list_rooms())
  end

  def assign_active_room(socket, id) do
    assign(socket, :room, Chat.get_room!(id))
  end

  def assign_active_room(socket) do
    assign(socket, :room, nil)
  end

  def assign_scrolled_to_top(socket, scrolled_to_top) do
    assign(socket, :scrolled_to_top, scrolled_to_top)
  end
end
