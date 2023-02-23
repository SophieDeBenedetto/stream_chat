defmodule StreamChat.Chat.Message.Query do
  import Ecto.Query
  alias StreamChat.Chat.Message

  def base do
    Message
  end

  def preload_sender do
    base()
    |> join(:inner, [m], s in assoc(m, :sender))
    |> limit(10)
    |> preload([m, s], sender: s)
  end
end
