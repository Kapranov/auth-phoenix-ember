defmodule BackendWeb.UserController do
  use BackendWeb, :controller

  alias Backend.Actors

  action_fallback BackendWeb.FallbackController

  def index(conn, _params) do
    users = Actors.list_users()
    render(conn, "index.json-api", data: users)
  end
end
