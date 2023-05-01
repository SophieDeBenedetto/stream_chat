defmodule StreamChatWeb.PageController do
  use StreamChatWeb, :controller
  require Logger

  def home(conn, _params) do
    Logger.info("hello from the page contoller")
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end
