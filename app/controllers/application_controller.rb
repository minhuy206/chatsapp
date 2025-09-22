class ApplicationController < ActionController::Base
  include LoggingConcern
  allow_browser versions: :modern

  private
  def current_user
    nil
  end
end
