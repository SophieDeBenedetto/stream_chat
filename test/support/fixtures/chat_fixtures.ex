defmodule StreamChat.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StreamChat.Chat` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> StreamChat.Chat.create_room()

    room
  end
end
