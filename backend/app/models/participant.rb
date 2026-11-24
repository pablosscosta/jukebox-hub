# A guest who joined a party through the invite link. There is no login: the guest gets a
# random token when joining and sends it on every request.
class Participant < ApplicationRecord
  include DigestibleToken

  NAME_MAX_LENGTH = 40

  belongs_to :party

  validates :display_name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :token_digest, presence: true, uniqueness: true

  def self.authenticate(raw)
    return if raw.blank?

    find_by(token_digest: digest(raw))
  end
end
