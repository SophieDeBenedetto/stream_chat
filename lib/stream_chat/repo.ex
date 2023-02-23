defmodule StreamChat.Repo do
  use Ecto.Repo,
    otp_app: :stream_chat,
    adapter: Ecto.Adapters.Postgres
end
