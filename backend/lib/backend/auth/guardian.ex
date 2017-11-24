defmodule Backend.Auth.Guardian do
  use Guardian, otp_app: :backend

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
