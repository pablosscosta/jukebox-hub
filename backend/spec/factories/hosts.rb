FactoryBot.define do
  factory :host do
    sequence(:spotify_user_id) { |n| "spotify-user-#{n}" }
    display_name { "Pablo" }
    access_token { "spotify-access-token" }
    refresh_token { "spotify-refresh-token" }
    token_expires_at { 1.hour.from_now }

    trait :with_expired_spotify_token do
      token_expires_at { 1.minute.ago }
    end
  end
end
