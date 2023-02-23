defmodule StreamChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      StreamChatWeb.Telemetry,
      # Start the Ecto repository
      StreamChat.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: StreamChat.PubSub},
      # Start Finch
      {Finch, name: StreamChat.Finch},
      # Start the Endpoint (http/https)
      StreamChatWeb.Endpoint
      # Start a worker by calling: StreamChat.Worker.start_link(arg)
      # {StreamChat.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StreamChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StreamChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
