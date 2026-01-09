class UserSerializer < ActiveModel::Serializer
  attributes :id, :display_name, :joined_at
end
