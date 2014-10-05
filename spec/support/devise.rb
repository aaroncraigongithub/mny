
def auth_user(role = :user)
  user = nil
  if role.is_a?(User)
    user = role
  else
    user = create(role)
  end

  sign_in user
end
