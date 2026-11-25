module Parties
  # Starts a party for the host on one of their Spotify devices.
  class Create
    class PremiumRequired < StandardError; end

    # The device isn't among the host's controllable devices anymore (Spotify was closed on
    # it, or the id is made up).
    class DeviceUnavailable < StandardError; end

    class ActivePartyExists < StandardError
      attr_reader :party

      def initialize(party)
        super("Host already has an active party")
        @party = party
      end
    end

    def self.call(...) = new(...).call

    def initialize(host:, name:, device_id:, spotify:)
      @host = host
      @name = name.to_s.strip
      @device_id = device_id
      @spotify = spotify
    end

    def call
      raise PremiumRequired unless @host.premium?

      end_expired_parties
      raise ActivePartyExists, @host.current_party if @host.current_party

      save_party(find_device!)
    end

    private

    # Another request may create a party between the check above and this insert. Depending
    # on timing, either the uniqueness validation or the unique index stops this one.
    def save_party(device)
      @host.parties.create!(name: @name, device_id: device.id, device_name: device.name)
    rescue ActiveRecord::RecordNotUnique
      raise ActivePartyExists, @host.current_party
    rescue ActiveRecord::RecordInvalid => e
      raise unless e.record.errors.of_kind?(:host_id, :taken)

      raise ActivePartyExists, @host.current_party
    end

    # An expired party stays "active" until something closes it. Closing it here keeps it from
    # blocking the new one.
    def end_expired_parties
      @host.parties.overdue.find_each { |party| Parties::End.call(party:) }
    end

    def find_device!
      @spotify.devices.find { |device| device.controllable? && device.id == @device_id } ||
        raise(DeviceUnavailable)
    end
  end
end
