defmodule StreamChatWeb.ChatLive.Room do
  use StreamChatWeb, :live_component
  import StreamChatWeb.CoreComponents
  alias StreamChatWeb.ChatLive.Message

  def render(assigns) do
    ~H"""
    <div id={"room-#{@room.id}"}>
      <.list_messages messages={@messages} />
      <.live_component
        module={Message.Form}
        room_id={@room.id}
        sender_id={@current_user_id}
        id={"room-#{@room.id}-message-form"}
      />
    </div>
    """
  end

  def list_messages(assigns) do
    ~H"""
    <div id="messages" phx-update="stream" class="overflow-scroll" style="height: calc(88vh - 10rem)" phx-hook="ScrollDown">
      <.message_list :for={{dom_id, message} <- @messages}>
        <:message dom_id={dom_id} title={message.sender.email} created_at={message.inserted_at}>
          <%= message.content %>
        </:message>
      </.message_list>
    </div>
    """
  end
end
