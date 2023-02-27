defmodule StreamChatWeb.ChatLive.Message do
  use StreamChatWeb, :html
  import StreamChatWeb.CoreComponents

  def show(assigns) do
    ~H"""
    <.message_meta message={@message} />
    <.message_content message={@message} />
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
