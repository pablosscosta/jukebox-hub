FactoryBot.define do
  factory :queue_item do
    participant
    party { participant.party }
    sequence(:track_id) { |n| format("track%017d", n) }
    title { "Garota de Ipanema" }
    artist { "Tom Jobim" }
    duration_ms { 323_000 }
    image_url { "https://i.scdn.co/image/300" }

    trait :playing do
      status { :playing }
      started_at { Time.current }
    end

    trait :played do
      status { :played }
      started_at { 5.minutes.ago }
    end
  end
end
