class SessionSerializer < ActiveModel::Serializer
  attributes :id, :session_name, :status, :share_link, :qr_code_url

  has_many :users
  has_many :queue_items
end
