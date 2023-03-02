defmodule StreamChatWeb.ChatLive.Room do
  use Phoenix.Component
  alias StreamChatWeb.ChatLive.{Messages, Message}

  def show(assigns) do
    ~H"""
    <div id={"room-#{@room.id}"}>
      <Messages.list_messages messages={@messages} scrolled_to_top={@scrolled_to_top} />
      <.live_component
        module={Message.Form}
        room_id={@room.id}
        sender_id={@current_user_id}
        id={"room-#{@room.id}-message-form"}
      />
    </div>
    """
  end
end
