defmodule StreamChatWeb.RoomLive.Show do
  use StreamChatWeb, :live_component
  import StreamChatWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div>
      <.messages room={@room} />
    </div>
    """
  end

  def messages(assigns) do
    ~H"""
    <.message_list :for={message <- @room.messages}>
      <:item title={message.sender.email}><%=message.content %></:item>
    </.message_list>
    """
  end
end
