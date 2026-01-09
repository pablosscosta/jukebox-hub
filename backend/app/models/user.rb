class User < ApplicationRecord
  belongs_to :session

  validates :display_name, length: { maximum: 50 }, presence: true

  def can_add_song?
    
  end
end
