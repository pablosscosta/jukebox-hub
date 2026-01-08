class Session < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :queue_items, dependent: :destroy
end
