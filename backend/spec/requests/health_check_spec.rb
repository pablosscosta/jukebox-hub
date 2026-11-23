require "rails_helper"

RSpec.describe "Health check" do
  describe "GET /up" do
    it "responds with success when the app boots" do
      get "/up"

      expect(response).to have_http_status(:ok)
    end
  end
end
