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
