# Keys for Active Record Encryption (used for the host's Spotify tokens).
#
# They are derived from secret_key_base instead of living in their own secrets, so there is
# nothing extra to configure: in production secret_key_base comes from the credentials
# (RAILS_MASTER_KEY); in development and test Rails generates one in tmp/.
# Trade-off: rotating secret_key_base makes the stored tokens unreadable, and hosts simply
# log in again. See docs/adr/0006-autenticacao-do-host.md.
Rails.application.config.after_initialize do
  key_generator = Rails.application.key_generator

  ActiveRecord::Encryption.configure(
    primary_key: key_generator.generate_key("active_record_encryption/primary_key", 32).unpack1("H*"),
    deterministic_key: key_generator.generate_key("active_record_encryption/deterministic_key", 32).unpack1("H*"),
    key_derivation_salt: key_generator.generate_key("active_record_encryption/key_derivation_salt", 32).unpack1("H*")
  )
end
