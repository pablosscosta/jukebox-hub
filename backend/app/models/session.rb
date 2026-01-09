class Session < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :queue_items, dependent: :destroy

  validates :session_name, presence: true, uniqueness: true
  validates :host_user_id, presence: true
  validates :device_id, presence: true
  validates :status, inclusion: { in: ["Active", "Ended"] }
end
