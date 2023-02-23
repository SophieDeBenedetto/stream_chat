defmodule StreamChat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :string
      add :sender_id, references(:users), null: false
      add :room_id, references(:rooms), null: false

      timestamps()
    end
  end
end
