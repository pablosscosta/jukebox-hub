FactoryBot.define do
  factory :party do
    host
    name { "Churrasco de sábado" }
    device_id { "device-1" }
    device_name { "Notebook" }

    trait :ended do
      status { :ended }
    end

    trait :expired do
      expires_at { 1.minute.ago }
    end
  end
end
