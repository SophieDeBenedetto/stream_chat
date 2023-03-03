defmodule StreamChatWeb.ChatLive.Message.Form do
  use StreamChatWeb, :live_component
  import StreamChatWeb.CoreComponents
  alias StreamChat.Chat
  alias StreamChat.Chat.Message

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset}
  end

  def assign_changeset(socket) do
    assign(socket, :changeset, Chat.change_message(%Message{}))
  end

  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        phx-submit="save"
        phx-change="update"
        phx-target={@myself}
      >
        <.input
          autocomplete="off"
          phx-keydown={show_modal("edit_message")}
          phx-key="ArrowUp"
          phx-focus="unpin_scrollbar_from_top"
          field={{f, :content}}
        />
        <:actions>
          <.button>send</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("update", %{"message" => %{"content" => content}}, socket) do
    {:noreply, socket |> assign(:changeset, Chat.change_message(%Message{content: content}))}
  end

  def handle_event("save", %{"message" => %{"content" => content}}, socket) do
    Chat.create_message(%{
      content: content,
      room_id: socket.assigns.room_id,
      sender_id: socket.assigns.sender_id
    })

    {:noreply, assign_changeset(socket)}
  end
end
