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
    {:noreply,
     socket
     |> assign_active_room(id)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("unpin_scrollbar_from_top", _params, socket) do
    {:noreply,
     socket
     |> assign_scrolled_to_top("false")}
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

  def get_last_user_message_for_room(room_id, current_user_id) do
    Chat.last_user_message_for_room(room_id, current_user_id) || %Chat.Message{}
  end
end
