use Mix.Config

config :appsignal, :config,
  otp_app: :stream_chat,
  name: "stream_chat",
  # push_api_key: "ls-3e4ff5f9-7494-41cd-90c1-e372e80efd07",
  push_api_key: "0ab6fd4b-fe1c-41a0-9aa8-55f209276ce9",
  env: Mix.env()
