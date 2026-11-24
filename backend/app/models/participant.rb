# Someone in a party. Guests join through the invite link: there is no login, they get a random
# token when joining and send it on every request. The host is a participant of their own party
# too, so they can add songs; they keep using their host token and have no participant token.
class Participant < ApplicationRecord
  include DigestibleToken

  NAME_MAX_LENGTH = 40

  belongs_to :party

  enum :role, { guest: "guest", host: "host" }, validate: true

  validates :display_name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :token_digest, presence: true, if: :guest?
  validates :token_digest, uniqueness: true, allow_nil: true

  def self.authenticate(raw)
    return if raw.blank?

    find_by(token_digest: digest(raw))
  end
end
