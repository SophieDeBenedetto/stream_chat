# Building a Chat App with LiveView Streams

In this post, we'll build out a LiveView-backed chatroom app with the help of LiveView's new streams feature. Along the way, we'll leverage LiveView's powerful JS interop functionality to fully flesh out our chatting application, and you'll see how streams seamless integrate with LiveView JS and other behavior to power seamless and efficient UIs. We'll also demonstrate LiveView best practices as we write our code. We'll organize our UI with layered function and live components, make liberal use of the core components offered by the LiveView generator, and use single-purpose reducer functions in our live views to manage socket state.

## Introduction LiveView Streams

LiveView 0.18.16 ships with the new streams functionality for managing large collections of data client-side, without having to store anything in the LiveView socket. Chris McCord tells us more about this feature and the problem it's designed to solve in [this excellent post](https://fly.io/phoenix-files/phoenix-dev-blog-streams/).

For the past few years, a question I would often hear from devs interested in LiveView was: "What about large sets of data?" Users who needed to display and manage long lists of data had to store that data on the server, or else work with the `phx-update="append"` feature. Storing large collections server-side can impact performance, while the `phx-update="append"` feature had its own drawbacks. But, as is so often the case with LiveView over the course of its development, the framework has come to provide a better solution for this commonly expressed concern. Now, you can use streams to efficiently manage large datasets in your live views by detaching that data from the socket and letting the client store it instead of the server.

LiveView exposes an elegant and users-friendly API for storing data in a client-side stream and allowing your app's users to interact with that data by adding, updating, and deleting items in the stream. We'll explore this behavior as we build a real-time chat feature into an existing chatroom-style LiveView application. Let's get started.

## The StreamChat App

For this project, we have a basic LiveView application set up with the following domain:

* A `Room` has many messages.
* A `Message` belongs to a room and a sender. A sender is a user.
* A `User` has many messages.

We also have a `Chat` context that exposes the CRUD functionality for rooms and messages. All of this backs the main live view of the application, `StreamChatWeb.ChatLive.Root`. This live view is mapped to the `/rooms` and `/rooms/:id` live routes and this is where we'll be building out our stream-backed chatting feature. You can find the completed code for this project [here](https://github.com/SophieDeBenedetto/stream_chat), including a seed file that will get you started with some chat rooms, users, and messages.

Let's assume we've built out the entities described here, leaving us with this basic live view page:

![](rooms)

A user can navigate to `/rooms/:id` and see the sidebar that lists the available chatrooms, with the current chatroom highlighted. But, we're not displaying the messages for that room yet, nor do we have a form through which the user can submit a new message. This is where our stream functionality comes in so this is where we'll pick up with our coding. Let's go.

## List Messages with a LiveView Stream
- put stream in rooms state when handle_params says so
- pass to child component
- talk about components
- examine the stream

### Bonus: Automatic Scroll-down with JS Hooks

## Create a message with `stream_insert`

### Bonus: Real-Time Messaging with LiveView and PubSub

## Update a message with `stream_insert`

### Bonus: Showing and Hiding the Edit Form with JS Commands

## Delete a message with `stream_delete`

### Bonus: Showing and Hiding the Delete Button with JS Hooks
