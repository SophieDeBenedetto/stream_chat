defmodule StreamChatWeb.ChatLive.Root do
  use StreamChatWeb, :live_view
  alias StreamChat.Chat
  alias StreamChatWeb.Endpoint
  alias StreamChatWeb.ChatLive.{Rooms, Room, Message}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_rooms()
     |> assign_active_room()
     |> assign_scrolled_to_top()
     |> assign_last_user_message()}
  end

  def handle_params(%{"id" => id}, _uri, %{assigns: %{live_action: :show}} = socket) do
    if connected?(socket), do: Endpoint.subscribe("room:#{id}")

    {:noreply,
     socket
     |> assign_active_room(id)
     |> assign_active_room_messages()
     |> assign_last_user_message()}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_info(%{event: "new_message", payload: %{message: message}}, socket) do
    {:noreply,
     socket
     |> insert_new_message(message)
     |> assign_last_user_message(message)}
  end

  def handle_info(%{event: "updated_message", payload: %{message: message}}, socket) do
    {:noreply,
     socket
     |> insert_updated_message(message)
     |> assign_last_user_message(message)}
  end

  def handle_event("load_more", _params, socket) do
    messages = Chat.get_previous_n_messages(socket.assigns.oldest_message_id, 5)

    {:noreply,
     socket
     |> stream_batch_insert(:messages, messages, at: 0)
     |> assign_oldest_message_id(List.last(messages))
     |> assign_scrolled_to_top("true")}
  end

  def handle_event("unpin_scrollbar_from_top", _params, socket) do
    {:noreply,
     socket
     |> assign_scrolled_to_top("false")}
  end

  def handle_event("delete_message", %{"item_id" => message_id}, socket) do
    {:noreply, delete_message(socket, message_id)}
  end

  def insert_new_message(socket, message) do
    socket
    |> stream_insert(:messages, Chat.preload_message_sender(message))
  end

  def insert_updated_message(socket, message) do
    socket
    |> stream_insert(:messages, Chat.preload_message_sender(message), at: -1)
  end

  def assign_active_room_messages(socket) do
    messages = Chat.last_ten_messages_for(socket.assigns.room.id)

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

  def assign_scrolled_to_top(socket, scrolled_to_top \\ "false") do
    assign(socket, :scrolled_to_top, scrolled_to_top)
  end

  def assign_oldest_message_id(socket, message) do
    assign(socket, :oldest_message_id, message.id)
  end

  def assign_is_editing_message(socket, is_editing \\ nil) do
    assign(socket, :is_editing_message, is_editing)
  end

  def assign_last_user_message(%{assigns: %{current_user: current_user}} = socket, message)
      when current_user.id == message.sender_id do
    assign(socket, :message, message)
  end

  def assign_last_user_message(socket, _message) do
    socket
  end

  def assign_last_user_message(%{assigns: %{room: nil}} = socket) do
    assign(socket, :message, %Chat.Message{})
  end

  def assign_last_user_message(%{assigns: %{room: room, current_user: current_user}} = socket) do
    assign(socket, :message, get_last_user_message_for_room(room.id, current_user.id))
  end

  def delete_message(socket, message_id) do
    message = Chat.get_message!(message_id)
    Chat.delete_message(message)
    stream_delete(socket, :messages, message)
  end

  def get_last_user_message_for_room(room_id, current_user_id) do
    Chat.last_user_message_for_room(room_id, current_user_id) || %Chat.Message{}
  end
end
