defmodule StreamChatWeb.PageController do
  use StreamChatWeb, :controller
  require Logger

  def home(conn, _params) do
    Logger.info("hello from the page contoller", %{user_id: conn.assigns.current_user.id})
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end
