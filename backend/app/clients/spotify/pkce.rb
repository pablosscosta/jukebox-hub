module Spotify
  # PKCE (RFC 7636): we send Spotify the hash of a random secret (challenge) and later prove
  # we know the secret (verifier). A stolen authorization code is useless without it.
  module Pkce
    module_function

    def generate_verifier
      SecureRandom.urlsafe_base64(64)
    end

    def challenge_for(verifier)
      Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(verifier), padding: false)
    end
  end
end
