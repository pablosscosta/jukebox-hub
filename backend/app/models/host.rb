# The person who logs in with Spotify and runs parties. The music plays on their account.
class Host < ApplicationRecord
  encrypts :access_token, :refresh_token

  has_many :host_tokens, dependent: :delete_all
  has_many :parties, dependent: :delete_all

  validates :spotify_user_id, presence: true, uniqueness: true
  validates :access_token, :refresh_token, :token_expires_at, presence: true

  # Controlling playback through the Spotify API requires Premium.
  def premium?
    product == "premium"
  end

  # The party the host is running now. An active party past its expiration doesn't count:
  # it just hasn't been closed yet.
  def current_party
    parties.active.find_by(expires_at: Time.current..)
  end

  # Considers the token expired a little early so a request never starts with a token
  # that dies halfway through.
  def spotify_token_expired?(leeway: 1.minute)
    token_expires_at <= leeway.from_now
  end
end
