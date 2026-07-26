# frozen_string_literal: true

module AuthHelpers
  def auth_headers(user: nil, scheme: 'test-corp')
    user ||= create_admin_user!
    ensure_test_org!(scheme)
    token = JsonWebToken.encode(
      user_id: user.id,
      role: user.role,
      scheme: scheme
    )
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json',
      'ACCEPT' => 'application/json'
    }
  end

  def create_admin_user!
    User.find_or_create_by!(email: 'admin@test-corp.example') do |u|
      u.password = 'Password1!'
      u.role = 'admin'
    end
  end

  def ensure_test_org!(scheme = 'test-corp')
    org = Organization.find_by(scheme: scheme)
    return org if org

    Organization.create!(
      name: 'Test Corp',
      scheme: scheme,
      identifier: scheme,
      host: 'localhost',
      alias_hosts: [],
      config: {}
    )
  end
end
