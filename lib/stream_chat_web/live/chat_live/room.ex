defmodule StreamChatWeb.ChatLive.Room do
  use Phoenix.Component
  alias StreamChatWeb.ChatLive.Message
  import StreamChatWeb.CoreComponents

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
        <.message_meta message={message} />
        <.message_content message={message} />
      </div>
    </div>
    """
  end

  def message_meta(assigns) do
    ~H"""
    <dl class="-my-4 divide-y divide-zinc-100">
      <div class="flex gap-4 py-4 sm:gap-2">
        <.user_icon />
        <dt class="w-1/8 flex-none text-[0.8125rem] leading-6 text-zinc-500" style="font-weight: 900">
          <%= @message.sender.email %>
          <span style="font-weight: 300">[<%= @message.inserted_at %>]</span>
        </dt>
      </div>
    </dl>
    """
  end

  def message_content(assigns) do
    ~H"""
    <dl class="-my-4 divide-y divide-zinc-100">
      <div class="flex gap-4 py-4 sm:gap-2">
        <dd class="text-sm leading-6 text-zinc-700" style="margin-left: 2%;margin-top: -1%;">
          <%= @message.content %>
        </dd>
      </div>
    </dl>
    """
  end
end
