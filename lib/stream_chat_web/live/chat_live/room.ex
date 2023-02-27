defmodule StreamChatWeb.ChatLive.Room do
  use Phoenix.Component
  alias StreamChatWeb.ChatLive.Message
  # import StreamChatWeb.CoreComponents

  def show(assigns) do
    ~H"""
    <div id={"room-#{@room.id}"}>
      <.messages_list messages={@messages} scrolled_to_top={@scrolled_to_top} />
      <.live_component
        module={Message.Form}
        room_id={@room.id}
        sender_id={@current_user_id}
        id={"room-#{@room.id}-message-form"}
      />
    </div>
    """
  end

  def messages_list(assigns) do
    ~H"""
    <div
      id="messages"
      phx-update="stream"
      class="overflow-scroll"
      style="height: calc(88vh - 10rem)"
      phx-hook="ScrollDown"
      data-scrolled-to-top={@scrolled_to_top}
    >
      <div id="infinite-scroll-marker" phx-hook="InfiniteScroll"></div>
      <div :for={{dom_id, message} <- @messages} id={dom_id} class="mt-2">
        <Message.show message={message} />
      </div>
    </div>
    """
  end
end
