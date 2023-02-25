# StreamChat

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## TODO:
* Show user typing
* Add badge to room name when unread messages
* Track awareness of message read/unread
* Only scroll down for new messages if the message is from the current user
  * In handle_info for new message from PubSub, if new message is from self, scroll down. If from someone else, do not scroll but add badge to side/bottom instead. Use same pattern as 'scrollToTop' data element from socket state for updated() scrollDown Hook
* Refine JS interactions for infinite scroll back
