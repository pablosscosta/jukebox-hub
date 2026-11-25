module PartyEvents
  # The body of an SSE response: Puma calls #each and writes out each piece as it comes. It waits
  # for the party's notices on an in-memory queue (see Listener) and never touches the database.
  class Stream
    def initialize(party_id:, ended:, heartbeat:, lifetime:, on_heartbeat: -> {})
      @party_id = party_id
      @ended = ended
      @heartbeat = heartbeat
      @lifetime = lifetime
      @on_heartbeat = on_heartbeat
      @listener = Listener.instance
    end

    def each(&)
      return yield(event("party_ended")) if @ended

      queue = @listener.subscribe(@party_id)
      yield event("connected")
      relay(queue, &)
    ensure
      # Also runs when the phone leaves: writing to a closed connection stops #each with an error.
      @listener.unsubscribe(@party_id, queue) if queue
    end

    private

    # Writes each notice as it arrives, or a heartbeat when none came, until the stream gets old.
    def relay(queue)
      deadline = @lifetime.from_now
      while Time.current < deadline
        notice = queue.pop(timeout: @heartbeat.to_f)
        yield(notice ? event(notice) : heartbeat)
        break if notice == "party_ended"
      end
    end

    def event(name)
      "event: #{name}\ndata: {}\n\n"
    end

    # A comment line keeps the connection alive.
    def heartbeat
      @on_heartbeat.call
      ": heartbeat\n\n"
    end
  end
end
