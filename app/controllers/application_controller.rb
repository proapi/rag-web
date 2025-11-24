class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Detect if the request is coming from a Turbo Native app
  def turbo_native_app?
    request.user_agent.to_s.match?(/Turbo Native/)
  end
  helper_method :turbo_native_app?
end
