# Building a Chat App with LiveView Streams

In this post, we'll build out a LiveView chatroom app with the help of LiveView's new LiveStream feature. You'll see how streams seamlessly integrate into your existing live views to power interactive and efficient UIs. Along the way, we'll look at how streams work under the hood. When we're done, you'll have exercised the full functionality of LiveStream and you'll understand how streams work at a deep level.

## What are LiveView Streams?

LiveView 0.18.16 ships with the new streams functionality for managing large collections of data client-side, without having to store anything in the LiveView socket. Chris McCord tells us more about this feature and the problem it's designed to solve in [this excellent post](https://fly.io/phoenix-files/phoenix-dev-blog-streams/).

For the past few years, a question I would often hear from developers interested in LiveView was: "What about large datasets?" Users who needed to display and manage long lists of data had to store that data on the server, or else work with the `phx-update="append"` feature. Storing large collections server-side can impact performance, while the `phx-update="append"` feature had its own drawbacks. But, as is so often the case with LiveView over the course of its development, the framework has come to provide a better solution for this commonly expressed concern. Now, you can use streams to efficiently manage large datasets in your live views by detaching that data from the socket and letting the client store it instead of the server.

LiveView exposes an elegant and users-friendly API for storing data in a client-side stream and allowing your app's users to interact with that data by adding, updating, and deleting items in the stream. We'll explore this behavior as we build a real-time chat feature into an existing chatroom-style LiveView application. Our chat will even use streams to support an infinite scroll back feature that allows users to view their chat history. Let's get started.

## The StreamChat App

For this project, we have a basic LiveView application set up with the following domain:

* A `Room` has many messages.
* A `Message` belongs to a room and a sender. A sender is a user.
* A `User` has many messages.

We also have a `Chat` context that exposes the CRUD functionality for rooms and messages. All of this backs the main live view of the application, `StreamChatWeb.ChatLive.Root`. This live view is mapped to the `/rooms` and `/rooms/:id` live routes and this is where we'll be building out our stream-backed chatting feature. You can find the starting code for this project [here](https://github.com/SophieDeBenedetto/stream_chat), including a seed file that will get you started with some chat rooms, users, and messages. If you'd like to follow along step-by-step with this post, clone down the repo at the `start` branch. Or, you can check out the completed project [here](https://github.com/SophieDeBenedetto/stream_chat).

Let's assume we've built out the entities described here, leaving us with this basic live view page:

![](room-without-messages)

A user can navigate to `/rooms/:id` and see the sidebar that lists the available chatrooms, with the current chatroom highlighted. But we're not displaying the messages for that room yet. And, while we have the form for a new message, the page doesn't yet update to reflect that new message in real-time. We'll use streams to implement both of these features. Let's get started.

## List Messages with Streams

First up, we want to render a list of messages in each chat room. Here's the UI we're going for:

![](room-show)

We'll use a stream to store the most recent ten messages for the room and we'll render the contents of that stream in a HEEx template. Let's start by teaching the `ChatLive.Root` live view to query for the messages and put them in a stream when the `/rooms/:id` route is requested.

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

Note that both the `/rooms` and `/rooms/:id` routes map to the same live view, `ChatLive.Root`. The `/rooms/:id` route is defined with a live action of `:show` in the socket assigns. So, we'll define a `handle_params/3` callback that will run when the live action assignment is set to `:show`. We'll use this callback to fetch the list of messages for the current room and store them in the stream, like this:

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

First, we use a single-purpose reducer function to assign the room with the given ID to the socket. Then, we pass that updated socket to another reducer function, `assign_active_room_messages/1`. That reducer pulls the room out of socket assigns and uses it to fetch the last ten messages. Finally, we create a stream for `:messages` with a value of this list of messages.

Let's dive a bit deeper into streams and take a closer look at what happens when we call `stream(socket, :messages, Chat.last_ten_messages_for_room(room.id))`. Go ahead and pipe the updated socket into an `IO.inspect` like this:

```elixir
def assign_active_room_messages(%{assigns: %{room: room}} = socket) do
  stream(socket, :messages, Chat.last_ten_messages_for(room.id))
  |> IO.inspect
end
```

Let the live view reload and you should see the socket inspected into the terminal. Looking closely at the `assigns` key, you'll see something like this:

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

This is where the magic happens. We create a container div with a unique id of `"messages"` and a `phx-update="stream"` attribute. Both of these attributes are required in order for LiveView streams to be rendered and managed correctly. Then, we iterate over the `@messages` assignment, which we passed in all the way from the `root.html.heex` template's call to `@streams.messages`. At this point, `@messages` is set equal to the `Phoenix.LiveView.LiveStream` struct. This struct is enumerable such that when we iterate over it, it will yield tuples describing each item in the `:inserts` key. The first element of the tuple is the item's DOM id and the second element is the message struct itself. LiveView uses each item's DOM id to manage stream items on the page. More on that in a bit.

[**Deep Dive: How LiveStream Implements Iteration**]

_Keep reading if you want a closer look at how LiveStream implements enumeration. Or, skip this section to continue building the chat feature and return here later._

The LiveStream struct implements the `Enumerable` protocol [here](https://github.com/phoenixframework/phoenix_live_view/blob/v0.18.16/lib/phoenix_live_view/live_stream.ex#L55) which let's us iterate over it and yield the tuples described above. Here's a look at one of protocol's `reduce` functions:

```elixir
def reduce(%LiveStream{inserts: inserts}, acc, fun) do
  do_reduce(inserts, acc, fun)
end
```

You can see that when `reduce` is called, it pattern matches the _inserts_ out of the function head and passes that list into `do_reduce/3`. The `:inserts` key of the stream struct looks something like this:

```elixir
[
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
  # ...
]
```

It is a list of three-tuples, where the first element is the DOM id, the second element is an instruction to the LiveView client regarding where to position the item in the list (we don't care about that right now), and the third element is the item itself.

Here's a simplified look at the version of the `do_reduce/3` function that does the heavy lifting:

```elixir
defp do_reduce([{dom_id, _at, item} | tail], {:cont, acc}, fun) do
  do_reduce(tail, fun.({dom_id, item}, acc), fun)
end
```

The function ignores the `_at` element in the tuple, and collects new tuples composed of `{dom_id, item}`. So, when we iterate of a LiveStream struct with a `for` comprehension, it will yield these tuples.

[**/Deep Dive**]

Let's inspect this iteration more closely. Go ahead and add this code to the `list_messages/1` function and then hop on over to your terminal:

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

You can see that each tuple has a first element of the DOM id and a second element of the message itself. The DOM id of each element is computed by interpolating the name of the stream, in our case `"messages"`, along with the ID of the item. So, we get a DOM id of `"messages-5"` and so on.

**[Deep Dive] How LiveView computes the stream item DOM id:**

_Keep reading to take a deep dive into how LiveView computes the DOM id. Or, skip this section to continue   building our feature and return to it later_.

When you call `stream(socket, :messages, message_list)`, LiveView initializes a new LiveStream struct with the `Phoenix.LiveView.LiveStream.new/3` function. That function assigns the struct's `:dom_id` attribute to either a function you optionally provide to `stream/4`, or to the default DOM id function. Here's a peak at the source code:

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

It creates a variable, `dom_prefix` by stringifying the name of the stream--in our case `:messages`. Then, it sets `dom_id` either to a function you pass into `stream/4` like this: `stream(:messages, messages, &myFunc)`, or to an anonymous function that wraps the `default_id/2` function. Let's peek at the `default_id/2` function now:

```elixir
defp default_id(dom_prefix, %{id: id} = _struct_or_map), do: dom_prefix <> "-#{to_string(id)}"
```

The function is pretty straightforward, it returns a string that prepends the `dom_prefix` to the stringified item id.

As you can see above, the `dom_id` function is then called when `LiveStream.new` iterates over the list of items to be inserted:

```elixir
items_list = for item <- items, do: {dom_id.(item), -1, item}
```

For each item in the list, this iteration creates a three-tuple where the first element is the result of invoking the `dom_id` function for the given item. So, we end up with tuples in which the first element is something like `"messages-52"`, and so on.

[**/Deep Dive**]

LiveView uses the DOM id of each stream item to track that item and allow us to edit and delete the item. LiveView needs this DOM id to be attached to the HTML element that contains the stream item because stream data is not stored in socket assigns after the initial render. So, LiveView must be able to derive all the information it needs about the item and its position in the stream from the rendered HTML itself.

We attach the DOM id to each div produced by the iteration in our `:for` directive. Here's another look at that code:

```html
<div :for={{dom_id, message} <- @messages} id={dom_id}>
  <.message_meta message={message} />
  <.message_content message={message} />
</div>
```

That's all we need to do to render the list of messages from the stream. We stored the initial stream in socket assigns, iterated over it, and rendered it using the required HTML structure and attributes. Now, the page will render with this list of messages from the stream, and the `ChatLive.Root` live view will no longer hold this list of messages in the `streams.messages` socket assigns. After the initial render, `socket.assigns.streams.messages` will look like this:

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

We'll see LiveView's stream updating capabilities in action in the next section. Next up, we'll build the infinite scroll back feature that loads the previous chat history as the user scrolls the chat window up. Each time the user scrolls up and hits the top of the chat window, we'll prepend an older batch of messages to the stream. You'll see that LiveView handles the work of how and where to prepend those messages on the page. All we have to do is tell LiveView that an item should be prepended to the stream, and the framework takes care of the rest. Let's do that now.

## Prepend Stream Messages for Infinite Scroll Back

Our app uses a JS hook to send the `"load_more"` event to the server when the user scrolls up to the top of the chat window. You can check out the hook implementation [here](). All you need to do is add a new div with the hook attached to the messages display, like this:

```elixir
def list_messages(assigns) do
  ~H"""
  <div id="messages" phx-update="stream">
    <div id="infinite-scroll-marker" phx-hook="InfiniteScroll"></div> <!-- add me! -->
    <div :for={{dom_id, message} <- @messages} id={dom_id}>
      <.message_meta message={message} />
      <.message_content message={message} />
    </div>
  </div>
  """
end
```

Now we're ready to handle the `"load_more"` event in our live view by prepending items to the stream.

### Prepend Stream Items

In the `ChatLive.Root` live view, we need an event handler to match the `"load_more"` event. Go ahead and implement the function definition like this:

```elixir
def handle_event("load_more", _params, socket) do
  # coming soon!
end
```

Our event handler needs to fetch the previous batch of messages from the database and prepend each of those messages to the stream. We do have a context function available to us to query for n messages older than a given ID: `Chat.get_previous_n_messages/2`, but we have one problem. Since LiveView does not store stream data in the socket, we have no way of knowing what the ID of the currently loaded oldest message is. So, we can't query for messages _older_ than that one. We need to store awareness of this "oldest message" ID in the socket. Let's fix that now and then we'll return to our event handler.

When do we have access to the oldest message in the stream? When we query for the messages to add to the initial stream in our `handle_params/3` callback. At that time, we should grab the oldest message and store its ID in socket assigns. Here's our updated `handle_params` function:

```elixir
def handle_params(%{"id" => id}, _uri, %{assigns: %{live_action: :show}} = socket) do
  messages = Chat.last_ten_messages_for(socket.assigns.room.id)
  {:noreply,
    socket
    |> assign_active_room(id)
    |> assign_active_room_messages(messages)
    |> assign_oldest_message_id(List.first(messages))}
end

# ...

def assign_active_room_messages(socket, messages) do
  stream(:messages, messages)
end

def assign_oldest_message_id(socket, message) do
  assign(socket, :oldest_message_id, message.id)
end
```

Now we can use the oldest message id in socket assigns to query for the previous batch of messages. Let's do that in our event handler now.

```elixir
def handle_event("load_more", _params, %{assigns: %{oldest_message_id: id}} = socket) do
  messages = Chat.get_previous_n_messages(id, 5)

  {:noreply,
    socket
    |> stream_batch_insert(:messages, messages, at: 0)
    |> assign_oldest_message_id(List.last(messages))}
end
```

We query for the previous five messages that are older than the current oldest message. Then, we insert this batch of five messages into the stream. Finally, we assign a new oldest message ID.

Let's take a closer look at the `stream_batch_insert` function now. This is a hand-rolled function since the streams API doesn't currently support a "batch insert" feature.

```elixir
def stream_batch_insert(socket, key, items, opts \\ %{}) do
  items
  |> Enum.reduce(socket, fn item, socket ->
    stream_insert(socket, key, item, opts)
  end)
end
```

Here, we iterate over the items with `Enum.reduce` using the socket as an accumulator. For each item, we insert it into the stream. In our event handler, we call `stream_batch_insert` with `opts` of `at: 0`. This option is then passed to the call to `stream_insert/4` for each item. As a result, we end up with a socket assigns with the following insertion instructions for LiveView:

```elixir
streams: %{
  __changed__: MapSet.new([:messages]),
  messages: %Phoenix.LiveView.LiveStream{
    name: :messages,
    dom_id: #Function<3.113057034/1 in Phoenix.LiveView.LiveStream.new/3>,
    inserts: [
      {"messages-111", 0,
        %StreamChat.Chat.Message{
          id: 111,
          content: "10",
          #...
        }},
      {"messages-110", 0,
        %StreamChat.Chat.Message{
          id: 110,
          content: "9",
          # ...
      }},
    ],
    deletes: []
  }
}
# ...
```

Notice that the second element of each tuple in the `:inserts` collection is `0`. This tells LiveView to insert these items at the _beginning_ of the stream on the page. When the page re-renders, it will display these five older messages in the correct order, at the top of the chat messages display. Here's what our feature looks like in action:

![](infinite-scrollback video)

Now that we've built out our infinite scroll back feature and seen how streams work to prepend new data, we'll quickly build out the form for a new message, and use streams to append new messages to the _end_ of the messages list.

## Append a New Message with `stream_insert`

We'll make short work of our "new message" feature. First, we'll add a form for a new message to the bottom of the chat room UI. We'll implement an event handler for that form that uses `stream_insert` to append the new message to the end of the stream so that it shows up at the bottom of the chat window. Let's get started.

### The New Message Form

Create a live component to render the new message form and handle its submission:

```elixir
# lib/stream_chat_web/chat_live/message/forme.x
defmodule StreamChatWeb.ChatLive.Message.Form do
  use StreamChatWeb, :live_component
  import StreamChatWeb.CoreComponents
  alias StreamChat.Chat
  alias StreamChat.Chat.Message

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset}
  end

  def assign_changeset(socket) do
    assign(socket, :changeset, Chat.change_message(%Message{}))
  end

  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        phx-submit="save"
        phx-target={@myself}
      >
        <.input field={{f, :content}} />
        <:actions>
          <.button>send</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("save", %{"message" => %{"content" => content}}, socket) do
    Chat.create_message(%{
      content: content,
      room_id: socket.assigns.room_id,
      sender_id: socket.assigns.sender_id
    })

    {:noreply, assign_changeset(socket)}
  end
end
```

Our component will be called with an assigns that contains the room ID and sender ID. It will establish a changeset for a new message and render the form for that changeset. Then, it implements an event handler for the `"save"` event that creates the new message with the content from the form and the sender and room ID from socket assigns.

Let's call on our message form in the `Room.show/1` function component, right under the messages list:

```elixir
defmodule StreamChatWeb.ChatLive.Room do
  use Phoenix.Component
  alias StreamChatWeb.ChatLive.{Messages, Message}

  def show(assigns) do
    ~H"""
    <div id={"room-#{@room.id}"}>
      <Messages.list_messages messages={@messages} />
      <.live_component
        module={Message.Form}
        room_id={@room.id}
        sender_id={@current_user_id}
        id={"room-#{@room.id}-message-form"}
      />
    </div>
    """
  end
end
```

Putting it all together, we should see our form displayed on the page like this:

![](room show with form)

We're ready to teach our live view to insert the new message once it's created. This is the responsibility of the `ChatLive.Root` live view, since that is the live view that has awareness of the `@streams.messages` assignment. Luckily for us, our chat feature is already backed by PubSub for real-time capabilities. The []`Chat.create_message/1` function]() broadcasts an event when a new message is created, like this:

```elixir
Endpoint.broadcast(
  "room:#{message.room_id}",
  "new_message",
  %{message: message})
```

We just need to tell our `ChatLive.Root` live view to subscribe to the PubSub topic for the active room. We'll do that in `handle_params/3`:

```elixir
def handle_params(%{"id" => id}, _uri, %{assigns: %{live_action: :show}} = socket) do
  if connected?(socket), do: Endpoint.subscribe("room:#{id}")

  # ...
end
```

Now, when a new message is created, any `ChatLive.Root` live view processes for that message's room will receive a PubSub event. The `handle_info/3` for this event is where we'll insert the new chat message into the stream. Let's do it.

### Append a Stream Item

```elixir
def handle_info(%{event: "new_message", payload: %{message: message}}, socket) do
  {:noreply, insert_new_message(socket, message)}
end

def insert_new_message(socket, message) do
  socket
  |> stream_insert(:messages, Chat.preload_message_sender(message))
end
```

This time around, we call `stream_insert/4` with no additional options. In this case, the resulting LiveStream struct in socket assigns will look something like this:

```elixir
streams: %{
  __changed__: MapSet.new([:messages]),
  messages: %Phoenix.LiveView.LiveStream{
    name: :messages,
    dom_id: #Function<3.113057034/1 in Phoenix.LiveView.LiveStream.new/3>,
    inserts: [
      {"messages-111", -1,
        %StreamChat.Chat.Message{
          id: 111,
          content: "10",
          #...
        }
      },
    ],
    deletes: []
  }
}
# ...
```

Once again, we have a LiveStream struct with the `:inserts` key populated with the list of inserts. Now we have just one item in the list. The tuple representing that item has a second element of `-1`. This tells LiveView to append the new item to the end of the stream. As a result, the new message will be rendered at the end of the list of messages on the page.

That's it for our new message feature. Once again, streams did the heavy lifting for us. All we had to do was tell LiveView that a new item needed to appended. Now we're ready to build the edit message feature and take a look at how to update items in a stream. Then, we'll wrap up with our delete message feature.

## Update an Existing Message with `stream_insert`

The edit message form lives in the `ChatLive.Message.EditForm` live component, which is contained in a modal that we show or hide based on user interactions. We won't dive into the details here, since we want to keep our attention focused on the streams code we need to write. You can check out the completed code [here]() to take a closer look at the form rendering functionality, which is backed by function components and JS commands.

For now, all you need to know is that the edit message form implements an event handler for the `"save"` action. That event handler calls `Chat.update message` which emits an `"updated_message"` event over PubSub just like we did when we created a new message. We'll implement a `handle_info` for this event in the `ChatLive.Root` live view, since that live view is responsible for managing the `@streams.messages` assigns. Let's do that now.

```elixir
def handle_info(%{event: "updated_message", payload: %{message: message}}, socket) do
  {:noreply,
    socket
    |> insert_updated_message(message)}
end

def insert_updated_message(socket, message) do
  socket
  |> stream_insert(:messages, Chat.preload_message_sender(message), at: -1)
end
```

Here, we call `stream_insert` yet again, this time with the updated message and the `at: -1` option. Since we're passing a message that the stream is already tracking on the page, LiveView will know to update the existing message item in the stream. The `at: -1` option tells LiveView to update the item at its current stream location, rather than appending it to the end of the list. Now, the page will re-render and display the updated in message in place.

Before we wrap up, we need to build out the message delete feature. Let's do that now.

## Delete a Message with `stream_delete`

We render a delete icon for each message when the message is hovered over, like this:

![](message delete button)

When the user clicks that button, we send a `"delete_message"` event to the live view. Let's handle that event now by deleting the message from the stream.

```elixir
def handle_event("delete_message", %{"item_id" => message_id}, socket) do
  {:noreply, delete_message(socket, message_id)}
end

def delete_message(socket, message_id) do
  message = Chat.get_message!(message_id)
  Chat.delete_message(message)
  stream_delete(socket, :messages, message)
end
```

We query for the message to be deleted, execute a call to delete that message from the database, and then tell the stream to delete the message from its list. The call to `steam_delete` returns a socket with an assigns that looks something like this:

```elixir
streams: %{
  __changed__: MapSet.new([:messages]),
  messages: %Phoenix.LiveView.LiveStream{
    name: :messages,
    dom_id: #Function<3.113057034/1 in Phoenix.LiveView.LiveStream.new/3>,
    inserts: [],
    deletes: ["messages-20"]
  }
}
```

Notice that `:inserts` is empty, but `:deletes` contains a list with the DOM id of the item to be deleted. This instructs LiveView to remove the item with that DOM id from the rendered list of `@streams.messages`. If you pass a struct to `stream_delete`, LiveView will compute the DOM id to be deleted. Alternatively, if you don't have access to that struct or don't want to query for it, you can give `stream_delete` a third argument of the DOM id directly, either by re-computing it yourself or invoking the live stream's `dom_id/2` function stored in `@streams.messages.dom_id`.

That's all we need to do to support our delete message functionality. Once we tell LiveView that there is a stream item to delete, the framework once again takes care of the rest. It re-renders the page, triggering LiveView JS framework code that removes the specified item from the rendered list of `@streams.messages`.

Okay, we've covered a lot of ground. Let's wrap up.

## Wrap Up

* Benefits of streams
* recap of how easy they are to work with
* recap of some of the "under the hood" glances we took to drive home that we understand how they work and they're not mysterious anymore
* highlight that we omitted a lot of functionality, especially JS functionality. Dive deeper into the full feature set in the codebase.
* Where will streams go next? I want a batch_insert.

Code TODO:
* clean starting branch for this tutorial -> starting state should have edit form and delete buttons on hover, but not handle_info to do stream insert/delete. Should have infinite scroll hook but not div to attach it. Should have create/update context functions with pubsub, but not handle infos.
* complete branch for this tutorial without scroll down JS bells and whistles, but with infinite scroll back, modal JS, hover JS. -> maybe not, maybe just fully completed branch.
* complete branch _with_ JS bells and whistles
* Link to code appropriately throughout
* Add images and videos
* Add demo at the top
