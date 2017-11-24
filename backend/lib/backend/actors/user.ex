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
