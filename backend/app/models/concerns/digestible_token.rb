# Random tokens stored only as a SHA-256 digest, so a database leak doesn't give anyone access.
# The raw value exists only in the response that hands it out.
module DigestibleToken
  extend ActiveSupport::Concern

  class_methods do
    def generate_token
      SecureRandom.urlsafe_base64(32)
    end

    def digest(raw)
      OpenSSL::Digest::SHA256.hexdigest(raw)
    end
  end
end
