defmodule StreamChat.Chat.Message.Query do
  import Ecto.Query
  alias StreamChat.Chat.Message

  def base do
    Message
  end

  def for_room(query \\ base(), room_id) do
    query
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], {:desc, m.inserted_at})
    |> limit(10)
    |> subquery()
    |> order_by([m], {:asc, m.inserted_at})
  end

  def preload_sender do
    base()
    |> join(:inner, [m], s in assoc(m, :sender))
    |> order_by([m], {:desc, m.inserted_at})
    |> limit(10)
    |> preload([m, s], sender: s)
  end
end
