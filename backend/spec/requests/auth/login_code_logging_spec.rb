require "rails_helper"

RSpec.describe "Login code in the logs" do
  let(:log) { StringIO.new }

  around do |example|
    original_logger = ActionController::Base.logger
    ActionController::Base.logger = ActiveSupport::Logger.new(log)
    example.run
  ensure
    ActionController::Base.logger = original_logger
  end

  it "is filtered from the redirect log line" do
    stub_spotify_token
    stub_spotify_me
    get "/auth/spotify"
    state = Rack::Utils.parse_query(URI(response.location).query)["state"]

    get "/auth/spotify/callback", params: { code: "auth-code", state: }

    login_code = Rack::Utils.parse_query(URI(response.location).query)["code"]
    expect(log.string).to include("Redirected to [FILTERED]")
    expect(log.string).not_to include(login_code)
  end
end
