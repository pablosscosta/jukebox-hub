FactoryBot.define do
  factory :participant do
    party
    sequence(:display_name) { |n| "Convidado #{n}" }
    token_digest { Participant.digest(Participant.generate_token) }

    trait :host do
      role { :host }
      token_digest { nil }
    end
  end
end
