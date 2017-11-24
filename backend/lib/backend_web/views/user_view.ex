defmodule BackendWeb.UserView do
  use BackendWeb, :view
  use JaSerializer.PhoenixView

  attributes [:email, :name, :is_admin]

  def type(_user, _conn), do: "users"
end
