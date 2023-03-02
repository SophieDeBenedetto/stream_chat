# Building a Chat App with LiveView Streams

In this post, we'll build out a LiveView-backed chatroom app with the help of LiveView's new streams feature. Along the way, we'll leverage LiveView's powerful JS interop functionality to fully flesh out our chatting application, and you'll see how streams seamless integrate with LiveView JS and other behavior to power seamless and efficient UIs. We'll also demonstrate LiveView best practices as we write our code. We'll organize our UI with layered function and live components, make liberal use of the core components offered by the LiveView generator, and use single-purpose reducer functions in our live views to manage socket state.

## Introduction LiveView Streams

LiveView 0.18.16 ships with the new streams functionality for managing large collections of data client-side, without having to store anything in the LiveView socket. Chris McCord tells us more about this feature and the problem it's designed to solve in [this excellent post](https://fly.io/phoenix-files/phoenix-dev-blog-streams/).

For the past few years, a question I would often hear from devs interested in LiveView was: "What about large sets of data?" Users who needed to display and manage long lists of data had to store that data on the server, or else work with the `phx-update="append"` feature. Storing large collections server-side can impact performance, while the `phx-update="append"` feature had its own drawbacks. But, as is so often the case with LiveView over the course of its development, the framework has come to provide a better solution for this commonly expressed concern. Now, you can use streams to efficiently manage large datasets in your live views by detaching that data from the socket and letting the client store it instead of the server.

LiveView exposes an elegant and users-friendly API for storing data in a client-side stream and allowing your app's users to interact with that data by adding, updating, and deleting items in the stream. We'll explore this behavior as we build a real-time chat feature into an existing chatroom-style LiveView application. Our chat will even use streams to support an infinite scroll back feature that allows users to view their chat history. Let's get started.

## The StreamChat App

For this project, we have a basic LiveView application set up with the following domain:

* A `Room` has many messages.
* A `Message` belongs to a room and a sender. A sender is a user.
* A `User` has many messages.

We also have a `Chat` context that exposes the CRUD functionality for rooms and messages. All of this backs the main live view of the application, `StreamChatWeb.ChatLive.Root`. This live view is mapped to the `/rooms` and `/rooms/:id` live routes and this is where we'll be building out our stream-backed chatting feature. You can find the starting code for this project [here](https://github.com/SophieDeBenedetto/stream_chat), including a seed file that will get you started with some chat rooms, users, and messages. If you'd like to follow along step-by-step with this post, clone down the repo at the `starting-state` branch. Or, you can check out the complete project [here]().

Let's assume we've built out the entities described here, leaving us with this basic live view page:

![](rooms)

A user can navigate to `/rooms/:id` and see the sidebar that lists the available chatrooms, with the current chatroom highlighted. But, we're not displaying the messages for that room yet, nor do we have a form through which the user can submit a new message. This is where our stream functionality comes in so this is where we'll pick up with our coding. Let's go.

## List Messages with a LiveView Stream

First up, we want to render a list of messages in each chat room. Here's the UI we're going for:

![](room-show)

We'll focus on the messages list first, and build out the form for a new message next. We'll use a stream to store the most recent ten messages for the room and we'll render the contents of that stream in a HEEx template. Let's start by teaching the `ChatLive.Root` live view to query for the messages and put them in a stream when the `/rooms/:id` route is requested.

### Initialize the Stream

In the `router.ex` file we have the following route definitions:

```elixir
live_session :rooms,
  on_mount: [{StreamChatWeb.UserAuth, :ensure_authenticated}],
  layout: {StreamChatWeb.Layouts, :rooms} do
  live "/rooms", ChatLive.Root, :index
  live "/rooms/:id", ChatLive.Root, :show
end
```

There are a few things to note here. First, the `/rooms` and `/rooms/:id` routes live in a shared live session that applies an authentication callback and a shared layout. The `StreamChatWeb.UserAuth.ensure_authenticated` callback was generated for us by the [Phoenix Auth generator](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html). It ensures that only logged in users can see these routes and it adds the `:current_user` key to the socket of any live views that back the routes in this live session. So, we know that the `ChatLive.Root` live view will have a socket with a `:current_user` available for free, and we don't have to write any additional code in that live view's mount function to query for and set the current user.

Next, note that both the `/rooms` and `/rooms/:id` routes map to the same live view, `ChatLive.Root`. The `/rooms/:id` route is defined with a live action of `:show` in the socket assigns. So, we'll define a `handle_params/3` callback that will run when the live action assignment is set to `:show`. We'll use this callback to fetch the list of messages and store them in the stream, like this:

```elixir
def handle_params(%{"id" => id}, _uri, %{assigns: %{live_action: :show}} = socket) do
  {:noreply,
    socket
    |> assign_active_room(id)
    |> assign_active_room_messages()}
end

# single-purpose reducer functions

def assign_active_room(socket, id) do
  assign(socket, :room, Chat.get_room!(id))
end

def assign_active_room_messages(%{assigns: %{room: room}} = socket) do
  stream(socket, :messages, Chat.last_ten_messages_for(room.id))
end
```

First, we use a single-purpose reducer function to assign the room with the given ID to the socket. Then, we pass that updated socket to another reducer function, `assign_active_room_messages/1`. That reducer pulls the room out of socket assigns and uses it to fetch the last ten messages. Finally, we create a stream for `:messages` with a value of this list of messages. These single-purpose reducer functions that take in a socket and annotate it with one additional key provide us with clean, re-usable LiveView code. They help us build narrative pipelines and can be re-used in other LiveView callbacks and event handlers. If you check out the full code for this live view [here](), you'll see that we implement an additional function head for the `assign_active_room` reducer and re-use it in the `mount/3` function.

Okay, let's dive a bit deeper into streams and take a closer look at what happens when we call `stream(socket, :messages, Chat.last_ten_messages_for_room(room.id))`. Go ahead and pipe the updated socket into an `IO.inspect` like this:

```elixir
def assign_active_room_messages(%{assigns: %{room: room}} = socket) do
  stream(socket, :messages, Chat.last_ten_messages_for(room.id))
  |> IO.inspect
end
```

Let the live view reload and you should see the socket inspected into the terminal. Looking closing at the `assigns` key, you'll see something like this:

```elixir
streams: %{
__changed__: MapSet.new([:messages]),
messages: %Phoenix.LiveView.LiveStream{
name: :messages,
dom_id: #Function<3.113057034/1 in Phoenix.LiveView.LiveStream.new/3>,
inserts: [
{"messages-5", -1,
  %StreamChat.Chat.Message{
    __meta__: #Ecto.Schema.Metadata<:loaded, "messages">,
    id: 5,
    content: "Iste cum provident tenetur.",
    room_id: 1,
    room: #Ecto.Association.NotLoaded<association :room is not loaded>,
    sender_id: 8,
    sender: #StreamChat.Accounts.User<
      __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
      id: 8,
      email: "keon@streamchat.io",
      confirmed_at: nil,
      inserted_at: ~N[2023-03-02 01:27:09],
      updated_at: ~N[2023-03-02 01:27:09],
      ...
    >,
    inserted_at: ~N[2023-03-02 01:27:10],
    updated_at: ~N[2023-03-02 01:27:10]
  }},
{"messages-8", -1,
  %StreamChat.Chat.Message{
    __meta__: #Ecto.Schema.Metadata<:loaded, "messages">,
    id: 8,
    content: "Ullam sit dolore quo dolores eos soluta.",
    room_id: 1,
    room: #Ecto.Association.NotLoaded<association :room is not loaded>,
    sender_id: 2,
    sender: #StreamChat.Accounts.User<
      __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
      id: 2,
      email: "d'angelo@streamchat.io",
      confirmed_at: nil,
      inserted_at: ~N[2023-03-02 01:27:08],
      updated_at: ~N[2023-03-02 01:27:08],
      ...
    >,
    inserted_at: ~N[2023-03-02 01:27:10],
    updated_at: ~N[2023-03-02 01:27:10]
  }},
{"messages-9", -1,
  %StreamChat.Chat.Message{
    __meta__: #Ecto.Schema.Metadata<:loaded, "messages">,
    id: 9,
    content: "Est veniam debitis quis rerum minus id facere aut rerum.",
    room_id: 1,
    room: #Ecto.Association.NotLoaded<association :room is not loaded>,
    sender_id: 9,
    sender: #StreamChat.Accounts.User<
      __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
      id: 9,
      email: "sadye@streamchat.io",
      confirmed_at: nil,
      inserted_at: ~N[2023-03-02 01:27:09],
      updated_at: ~N[2023-03-02 01:27:09],
      ...
    >,
    inserted_at: ~N[2023-03-02 01:27:10],
    updated_at: ~N[2023-03-02 01:27:10]
  }},
  # ...
  deletes: []
  }
},
# ...
```

The call to `streams/3` adds a `:streams` key to socket assigns, which in turn points to a map with a `:messages` key. The `streams.messages` assignment contains a `Phoenix.LiveView.LiveStream` struct that holds all of the info the LiveView client-side code needs to display your stream data on the page. Notice that the struct has an `:inserts` key that contains the list of messages we're inserting into the initial stream. It also contains a `:deletes` key that is currently empty. All of this data is made available in our template as the `@streams.messages` assignment, and we'll use it now to display the message list. Once that initial render occurs, the list of messages will no longer be present in the socket under `streams.messages.inserts`. It will be available only to the LiveView client-side code via the HTML on the page. Let's do that rendering now.

### Render Stream Data

We'll use a function component, `Room.show/1`, to render the messages list from the `root.html.heex` template if the `@live_action` assignment is set to `:show`. We'll pass in the messages from the stream when we do so, like this:

```elixir
# lib/stream_chat_web/live/chat_live/root.html.heex
<Room.show
  :if={@live_action == :show}
  messages={@streams.messages}
  current_user_id={@current_user.id}
  room={@room} />
```

The `Room.show/1` function component will eventually render both the list of messages _and_ a form for a new message. For now, it just renders the messages list, as shown here:

```elixir
defmodule StreamChatWeb.ChatLive.Room do
  use Phoenix.Component
  alias StreamChatWeb.ChatLive.Messages

  def show(assigns) do
    ~H"""
    <div id={"room-#{@room.id}"}>
      <Messages.list_messages messages={@messages} />
      <!-- new message form coming soon! -->
    </div>
    """
  end
end
```

This function component calls an another function component, `Messages.list/1`. This nice, layered UI allows us to wrap up the different concepts on our page into appropriately named functions. Each of these functions can be relatively single-purpose, keeping our code short and sweet and ensuring we have a nice clean location to place our stream rendering code. Let's take a look at that stream rendering code in `Messages.list/1` now.

```elixir
defmodule StreamChatWeb.ChatLive.Messages do
  use Phoenix.Component

  def list_messages(assigns) do
    ~H"""
    <div id="messages" phx-update="stream">
      <div :for={{dom_id, message} <- @messages} id={dom_id}>
        <.message_meta message={message} />
        <.message_content message={message} />
      </div>
    </div>
    """
  end
end
```

This is where the magic happens. We create a container div with a unique id of `"messages"` and a `phx-update="stream"` attribute. Both of these attributes are required in order for LiveView streams to be rendered and managed correctly. Then, we iterate over the `@messages` assignments, which we passed in all the way from the `root.html.heex` template's call to `@streams.messages`. At this point, `@messages` is set equal to the `Phoenix.LiveView.LiveStream` struct. This struct is enumerable such that when we iterate over it, it will yield tuples describing each item in the `:inserts` key, in which the first element is the elements DOM id and the second element is the message struct itself. Go ahead and add this code to the `list/1` function and then hop on over to your terminal:

```elixir
def list_messages(assigns) do
  for {dom_id, message} <- assigns.messages do
    IO.inspect {dom_id, message}
  end
  ~H"""
  # ...
  """
end
```

You should see something like this:

```elixir
{"messages-5",
 %StreamChat.Chat.Message{
   __meta__: #Ecto.Schema.Metadata<:loaded, "messages">,
   id: 5,
   content: "Iste cum provident tenetur.",
   room_id: 1,
   room: #Ecto.Association.NotLoaded<association :room is not loaded>,
   sender_id: 8,
   sender: #StreamChat.Accounts.User<
     __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
     id: 8,
     email: "keon@streamchat.io",
     confirmed_at: nil,
     inserted_at: ~N[2023-03-02 01:27:09],
     updated_at: ~N[2023-03-02 01:27:09],
     ...
   >,
   inserted_at: ~N[2023-03-02 01:27:10],
   updated_at: ~N[2023-03-02 01:27:10]
 }
}
 # ...
```

The DOM id of each element is computed by interpolating the name of the stream, in our case `"messages"`, along with the ID of the item. So, we get a DOM id of `"messages-5"` and so on.

**[Aside] How LiveView computes the stream item DOM id:** When you call `stream(socket, :messages, message_list)`, LiveView initializes a new `Phoenix.LiveView.LiveStream` struct with the `Phoenix.LiveView.LiveStream.new/3` function. That function creates a new `LiveStream` struct with a key of `:dom_id` pointing to either a function you optionally provide as an additional argument to `stream/4` like this: `stream(socket, :messages, messages, dom_id: &myFunc(&1)`, or pointing to the default DOM id function. Here's a peak at the source code:

```elixir
 def new(name, items, opts) when is_list(opts) do
  dom_prefix = to_string(name)
  dom_id = Keyword.get_lazy(opts, :dom_id, fn -> &default_id(dom_prefix, &1) end)

  unless is_function(dom_id, 1) do
    raise ArgumentError,
          "stream :dom_id must return a function which accepts each item, got: #{inspect(dom_id)}"
  end

  items_list = for item <- items, do: {dom_id.(item), -1, item}

  %LiveStream{
    name: name,
    dom_id: dom_id,
    inserts: items_list,
    deletes: [],
  }
end
```

Here's the interesting bit: `dom_id = Keyword.get_lazy(opts, :dom_id, fn -> &default_id(dom_prefix, &1) end)`. If you provide a function via the `:dom_id` option to your `stream/4` call, `dom_id` is set to that function. Otherwise, the `default_id` function is used, which looks like this:

```elixir
defp default_id(dom_prefix, %{id: id} = _struct_or_map), do: dom_prefix <> "-#{to_string(id)}"
```

As you can see above, `dom_id` function is called when `LiveStream.new` iterates over the list of items to be inserted. For each item in the list, it creates a three-tuple where the first element is the result of invoking the `dom_id` function for the given item.

[**/Aside**]

LiveView uses the DOM id of each stream item to track that item and allow us to edit the item, delete the item, and prepend or append new items. LiveView uses this DOM id, which we must attach to the HTMl element that contains the stream item, to manage stream data because the data is not stored in socket assigns after the initial render.

We're attaching the DOM id to each div produced by the iteration in our `:for` directive. Here's another look at that code:

```html
<div :for={{dom_id, message} <- @messages} id={dom_id}>
  <.message_meta message={message} />
  <.message_content message={message} />
</div>
```

For each tuple yielded by the iteration over `@messages`, we will render a div with an `id` set equal to that stream item's DOM id.

And that's all we need to do to render the list of messages from the stream. We stored the initial stream in socket assigns and rendered it using the required HTML structure and attributes. Now, the page will render with this list of messages from the stream, and the `ChatLive.Root` live view will no longer hold this list of messages in the `streams.messages` socket assigns. Instead, `socket.assigns.streams.messages` will look like this:

```elixir
streams: %{
  __changed__: MapSet.new([:messages]),
  messages: %Phoenix.LiveView.LiveStream{
  name: :messages,
  dom_id: #Function<3.113057034/1 in Phoenix.LiveView.LiveStream.new/3>,
  inserts: [],
  deletes: []
}
```

We'll see LiveView's stream updating capabilities in action in the next section. Next up, we'll build the infinite scroll back feature that loads the previous chat history as the user scrolls the chat window up. Each time the user scrolls up and hits the top of the chat window, we'll prepend an older batch of messages to the stream. You'll see that LiveView handles the work of figuring out how and where to prepend those messages on the page. It does so thanks to our correct rendering of stream items with their DOM ids. All we have to do is tell LiveView that an item should be prepended to the stream, and the framework takes care of the rest. Let's do that now.

## Infinite Scroll Back with Streams and JS Hooks

## Create a message with `stream_insert`

### Bonus: Real-Time Messaging with LiveView and PubSub

## Update a message with `stream_insert`

### Bonus: Showing and Hiding the Edit Form with JS Commands

## Delete a message with `stream_delete`

### Bonus: Showing and Hiding the Delete Button with JS Hooks
