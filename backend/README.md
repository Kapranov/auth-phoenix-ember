# Backend

So just to get started — this is the command that we’ll eventually
get to: `mix phx.new --no-brunch --no-html backend` or

```elixir
mix phx.new backend module Backend --app backend --no-brunch --no-html
```

This command will create a directory called `backend` with the module
being called `Backend` with the OTP app called `backend`. The asset
manager Brunch.io won’t be installed and it will tell the generator not
to create any HTML views.

There were four options in the documentation that called my attention:

```
* -app - the name of the OTP application
* -module - the name of the base module in the generated skeleton
* -no-brunch - do not generate brunch files for static asset building.
When choosing this option, you will need to manually handle JavaScript
dependencies if building HTML apps
* --no-html - do not generate HTML views.
```
So right now we have an almost Phoenix application, just a few
bits of boilerplate left to remove:

Removing channels and PubSub:

I imagine that despite the increasing impact and undeniable convenience
of WebSockets technology, many API servers still don't (yet) need
anything but a classical HTTP flow. If that is your case, you may want
to remove the channel boilerplate as well. You can always take a peak
into your repo's Git history and restore them when the time comes for
their great return.

PubSub is, to quote Phoenix documentation, a "nuts and bolts of
organizing Channel communication". Since we don't need channels, we
shouldn't need those nuts and bolts either.

First, delete the following files:

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

and file `lib/backend_web.ex`:

```elixir
  ...

  def channel do
    quote do
      use Phoenix.Channel
      import BackendWeb.Gettext
    end
  end

  ...
```

```bash
rm test/support/channel_case.ex
```

Then remove the following code references:

* `phoenix_pubsub` package from deps function in `mix.exs`

* `pubsub` key in `BackendWeb.Endpoint` config clause in
  `config/config.exs`

```elixir
config :backend, BackendWeb.Endpoint,
  ...

  pubsub: [name: Backend.PubSub,
           adapter: Phoenix.PubSub.PG2]

  ...
```

Unfortunately, it's not possible to unlock the `phoenix_pubsub` package
entirely as it's a dependency of Phoenix itself, but at least the
project code makes it clear about not being directly dependent on the
package or channels functionality.

Removing Gettext:

If you assume that the API messages (such as errors) are not supposed to
be consumed by end users, then the initial Gettext setup, as convenient
as it is, may be quite useless.

In my case, I've decided that my API will only return error codes (via
the code property of JSON API error objects) and it'll be up to the
front-end client (that lives in separate repo) to translate them for
the user. This way, only the client repo will have to bother with
translations and I won't have two separate Gettext translation sources
to maintain.

First, delete the following files:

```
rm lib/backend_web/gettext.ex
rm priv/gettext/errors.pot
rm priv/gettext/en/LC_MESSAGES/errors.po
```

Then remove the following code references:

* `gettext` package from deps function in `mix.exs`

```bash
defp deps do
  [
    ...

    {:gettext, "~> 0.11"},

    ...
  ]
end
```

* `gettext` compiler from compilers key in project function in `mix.exs`

```bash
def project do
  [
    ...

    compilers: [:phoenix] ++ Mix.compilers,

    ...
  ]
end
```

* `translate_error` function from `BackendWeb.ErrorHelpers` in file:
  `lib/backend_web/views/error_helpers.ex`


```elixir
defmodule BackendWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """
end
```

* all calls to `import BackendWeb.Gettext` in
  `lib/backend_web.ex` delete all strings with it.

Removing unneeded plugs:

As the final step, let's take a closer look at the plugs hooked by
default into the endpoint (defined in `lib/backend_web/endpoint.ex`).
If you do decide that any of plugs found there may not be  useful for
you, just remove the corresponding `plug` clause and enjoy having the
thinnest middleware stack possible.

The default `RequestId`, `Logger`, `MethodOverride` and `Head` plugs all
seem to fit the typical API server use case. The `Parsers` plug also
seems to be configured with reasonable and flexible defaults, allowing
the API to consume params from URL, multipart body and JSON body.

This leaves us with the following strong candidates for removal.

`Plug.Static` - This plug serves static assets from `priv/static` when
the server is running. Note that passing the `--no-brunch` option passed
to `mix phx.new` got us rid of the Brunch setup, but Phoenix assumes we
may still want to serve static files that we assemble with means other
than Brunch. This may not be the case if the API is just an API and all
the assets are bundled directly with the front-end project or otherwise
out of scope.

`Plug.Session` - This one gives us an out-of-the-box per-client session
store that lives on the client side in a cookie and that can be assumed
to be secure and impossible to tamper with from the client side thanks
to the server-side salt and optional encryption. While it's convenient
for traditional full-stack web applications, you may want to rethink its
use with API project for the following reasons:

* APIs often live on different domains than their clients which may be
  problematic for a cookie-based session store, as cookies are designed
  as a per-domain resources.
  *Solution proposal*: Cross-Origin Resource Sharing (`CORS`)

* Cookies are also prone to CSRF attacks and the most common protection
  against those - the CSRF token - is tricky and unnatural to apply for
  APIs.
  *Solution proposal*: `LocalStorage`, `SessionStorage`

* Each web framework's session is implemented in a non-standard way,
  which makes it hard to share with other services if your API grows and
  spans multiple servers and technologies.
  *Solution proposal*: `JSON Web Tokens`

* Concept of session as "an ability to continue a conversation with
  specific user's browser through a series of HTTP calls" is obsolete in
  a world with web sockets.
  *Solution proposal*: WebSockets (Phoenix channels)

If you stumble upon a use case where session seems to be necessary for
your API, you may need to rethink your architecture and reconsider
modern solutions to solve the above limitations.

## Install authentication packages

```elixir
  defp deps do
    [
      ...
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 1.0"},
      {:ja_serializer, "~> 0.12.0"},
      {:guardian, "~> 1.0.0"}
    ]
  end
```

Configure `config/config.exs`:

Secret key. You can use `mix guardian.gen.secret` to get one:

```elixir
config :phoenix, :format_encoders,
  "json-api": Poison

config :mime, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

config :backend, Backend.Auth.Guardian,
  issuer: "backend",
  secret_key: "KobAq3AgI0m6xPqN9y9xvwfpF4J63rYJ9s2+XVvEdHdtMVKYiOJPNemACRE/x5LB"
```

Now, jump in and create your first API resource, perhaps by invoking
`mix phx.gen.json`, because in Phoenix 1.3 this is where the real
context-driven fun starts.

```elixir
mix phx.gen.schema Actors.User users email:string:unique name:string password:string password_hash:string is_admin:boolean

mix ecto.migrate create_user
```

```elixir
# priv/repo/migrations/20171124160435_create_users.exs
defmodule Backend.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :password, :string
      add :password_hash, :string
      add :is_admin, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
```

```elixir
Backend.Repo.insert!(%Backend.Actors.User{email: "demo@example.com", name: "Demo", password: "123456789", is_admin: true})
Backend.Repo.insert!(%Backend.Actors.User{email: "test@example.com", name: "Test", password: "987654321", is_admin: false})
```

```elixir
# priv/repo/seeds.exs
alias Backend.Repo
alias Backend.Actors.User

Repo.insert!(%User{
  email: "demo@example.com",
  name: "Demo",
  is_admin: true,
  password: "123456789"
})

Repo.insert!(%User{
  email: "test@example.com",
  name: "Test",
  is_admin: false,
  password: "987654321"
})
```

```elixir
# lib/backend/actors/user.ex
defmodule Backend.Actors.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Backend.Actors.User


  schema "users" do
    field :email, :string
    field :is_admin, :boolean, default: false
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :name, :password, :is_admin])
    |> validate_required([:email, :name, :password, :is_admin])
    |> unique_constraint(:email)
    |> encrypt_password()
  end

  defp encrypt_password(changeset) do
    if changeset.valid? && Map.has_key?(changeset.changes, :password) do
      changeset
      |> put_change(:password_hash, Comeonin.Bcrypt.hashpwsalt(changeset.changes.password))
    else
      changeset
    end
  end
end
```

```bash
mkdir lib/backend/auth
touch lib/backend/auth/guardian.ex
```

```elixir
# lib/backend/auth/guardian.ex
defmodule Backend.Auth.Guardian do
  use Guardian, otp_app: :backend

  alias Backend.Actors
  alias Backend.Actors.User

  def subject_for_token(%User{} = user, _claims) do
    {:ok, user.id}
  end

  def subject_for_token(_) do
    {:error, "Unknown resource type"}
  end

  def resource_from_claims(claims) do
    {:ok, %{id: claims["sub"]}}
  end
end
```

```bash
touch lib/backend/actors/actors.ex
```

```elixir
# lib/backend/actors/actors.ex
defmodule Backend.Actors do
  import Ecto.Query, warn: false

  alias Backend.Repo
  alias Backend.Actors.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by(params), do: Repo.get_by(User, params)

  def create_user(%{"attributes" => attrs}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
```

```bash
touch lib/backend_web/controllers/user_controller.ex
touch lib/backend_web/controllers/fallback_controller.ex
```

```elixir
# lib/backend_web/controllers/user_controller.ex
defmodule BackendWeb.UserController do
  use BackendWeb, :controller

  alias Backend.Actors

  action_fallback BackendWeb.FallbackController

  def index(conn, _params) do
    users = Actors.list_users()
    render(conn, "index.json-api", data: users)
  end
end
```

```elixir
# lib/backend_web/controllers/fallback_controller.ex
defmodule BackendWeb.FallbackController do
  use BackendWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(BackendWeb.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(BackendWeb.ErrorView, :"404")
  end
end
```

```bash
touch lib/backend_web/views/user_view.ex
```

```elixir
# lib/backend_web/views/user_view.ex
defmodule BackendWeb.UserView do
  use BackendWeb, :view
  use JaSerializer.PhoenixView

  attributes [:email, :name, :is_admin]

  def type(_user, _conn), do: "users"
end
```

Edit Routes `lib/backend_web/router.ex`:

```elixir
# lib/backend_web/router.ex
defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/api", BackendWeb do
    pipe_through :api
    resources "/users", UserController, except: [:new, :edit]
  end
end
```

Check it out are requests:

```bash
mix phx.routes

user_path  GET     /api/users      BackendWeb.UserController :index
user_path  GET     /api/users/:id  BackendWeb.UserController :show
user_path  POST    /api/users      BackendWeb.UserController :create
user_path  PATCH   /api/users/:id  BackendWeb.UserController :update
           PUT     /api/users/:id  BackendWeb.UserController :update
user_path  DELETE  /api/users/:id  BackendWeb.UserController :delete

mix ecto.reset
mix test

iex -S mix phx.server

require Ecto.Query

alias Backend.Repo
alias Backend.Actors.User

User |> Ecto.Query.first  |> Repo.one
```
The result output:

```bash
http :4000/api/users

{
  "data": [
    {
      "attributes": {
        "email": "demo@example.com",
        "is-admin": true,
        "name": "Demo"
      },
      "id": "1",
      "type": "users"
    },
    {
      "attributes": {
        "email": "test@example.com",
        "is-admin": false,
        "name": "Test"
      },
      "id": "2",
      "type": "users"
    }
  ],
  "jsonapi": {
    "version": "1.0"
  }
}
```

The `Ecto.Repo.one` function will only return a struct if there is one
record in the result from the database. If there is more than one record
returned, an `Ecto.MultipleResultsError` exception will be thrown. Some
code that would cause that issue to happen is:

```elixir
alias Backend.Repo
alias Backend.Actors.User

User |> Repo.one
```

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Testing an application with `mix test`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
