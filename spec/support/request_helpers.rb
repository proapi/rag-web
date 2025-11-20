module RequestHelpers
  # Helper to authenticate as a user in request specs
  def sign_in(user)
    session = user.sessions.create!(
      user_agent: "Test User Agent",
      ip_address: "127.0.0.1"
    )

    # Create a signed cookie value that matches what Rails expects
    signed_value = Rails.application.message_verifier("signed cookie").generate(session.id)
    cookies[:session_id] = signed_value

    session
  end

  # For POST requests, add this to ensure CSRF protection is handled
  def post_with_auth(path, **args)
    post path, **args, headers: { "X-CSRF-Token" => "test-token" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request

  # Disable CSRF protection in request specs for easier testing
  config.before(:each, type: :request) do
    allow_any_instance_of(ActionController::Base).to receive(:verify_authenticity_token).and_return(true)
  end
end
