module Participants
  # A guest joins a party from the invite link and gets an anonymous token.
  class Join
    # The party ended or expired: it doesn't take new guests (it's read-only).
    class PartyClosed < StandardError; end

    Result = Data.define(:participant, :token)

    def self.call(...) = new(...).call

    def initialize(party:, display_name:)
      @party = party
      @display_name = display_name.to_s.strip
    end

    def call
      raise PartyClosed unless @party.open?

      token = Participant.generate_token
      participant = @party.participants.create!(display_name: name, token_digest: Participant.digest(token))
      Result.new(participant:, token:)
    end

    private

    # The name is optional. Without one the guest becomes "Convidado 1", "Convidado 2"... The
    # number is only a label: two guests joining at the same instant may get the same one.
    def name
      @display_name.presence || "Convidado #{@party.participants.guest.count + 1}"
    end
  end
end
