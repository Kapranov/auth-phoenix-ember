defmodule Backend.Actors.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Backend.Actors.User


  schema "users" do
    field :email, :string
    field :is_admin, :boolean, default: false
    field :name, :string
    field :password, :string
    field :password_hash, :string

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :name, :password, :password_hash, :is_admin])
    |> validate_required([:email, :name, :password, :password_hash, :is_admin])
    |> unique_constraint(:email)
  end
end
