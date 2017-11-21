# Backend

```elixir
mix phx.new --no-brunch --no-html backend
```

So right now we have an almost Phoenix application, just a few
bits of boilerplate left to remove:

* Thanks to the no-html and no-brunch we only have one file to remove:
  `rm lib/backend_web/channels/user_socket.ex`
* Remove `socket "/socket", BackendWeb.UserSocket` from:
  `lib/backend_web/endpoint.ex`, as we are creating a REST API, not
  sockets as amazing as they are.
* Tidy up `lib/backend_web/endpoint.ex` clearing out the `only:`
  static assets but leave it there for now as we will want it in a
  future.

```elixir
  socket "/socket", BackendWeb.UserSocket

  plug Plug.Static,
    at: "/", from: :backend, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  if code_reloading? do
    plug Phoenix.CodeReloader
  end
```

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
