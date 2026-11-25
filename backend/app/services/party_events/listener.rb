module PartyEvents
  # One per process: a thread that LISTENs on the events channel and hands each notice to the SSE
  # streams of that party. Streams wait on their own Thread::Queue, so they hold no database
  # connection while open: the whole process uses a single connection for listening.
  #
  # That connection is its own, opened outside Active Record's pool: a connection that spends its
  # life inside LISTEN must never be handed to a request afterwards.
  class Listener
    include Singleton

    # How long to wait for a notice before checking that the connection is still fine.
    WAIT_SECONDS = 30

    # autostart: false only in specs, to exercise the delivery without a LISTEN thread.
    def initialize(autostart: true)
      @autostart = autostart
      @streams = Hash.new { |hash, party_id| hash[party_id] = [] }
      @mutex = Mutex.new
    end

    # Returns the queue where this stream will receive the party's events.
    def subscribe(party_id)
      start if @autostart
      Thread::Queue.new.tap { |queue| @mutex.synchronize { @streams[party_id] << queue } }
    end

    # Ends the LISTEN thread (within WAIT_SECONDS) and frees its connection. Used before code is
    # reloaded in development: the reloaded class starts a listener of its own.
    def stop
      @stopped = true
    end

    def unsubscribe(party_id, queue)
      @mutex.synchronize do
        @streams[party_id].delete(queue)
        @streams.delete(party_id) if @streams[party_id].empty?
      end
    end

    # Hands a notice (the NOTIFY payload) to every stream of its party.
    def deliver(payload)
      notice = JSON.parse(payload)
      queues = @mutex.synchronize { @streams.fetch(notice["partyId"], []).dup }
      queues.each { |queue| queue << notice["event"] }
    rescue JSON::ParserError
      Rails.logger.warn("[party_events] ignored an invalid notice")
    end

    private

    def start
      @mutex.synchronize { @thread = Thread.new { listen_forever } unless @thread&.alive? }
    end

    def listen_forever
      loop do
        break if @stopped

        listen
      rescue StandardError => e
        # A dropped connection must not stop the events: log, wait a little and listen again.
        Rails.logger.error("[party_events] listener failed: #{e.class}: #{e.message}")
        sleep 1
      end
    end

    def listen
      pg = PG.connect(**connection_params)
      pg.exec("LISTEN #{CHANNEL}")
      pg.wait_for_notify(WAIT_SECONDS) { |_channel, _pid, payload| deliver(payload) } until @stopped
    ensure
      pg&.close
    end

    # Same database as Active Record (config/database.yml or DATABASE_URL).
    def connection_params
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      { host: config[:host], port: config[:port], dbname: config[:database], user: config[:username],
        password: config[:password] }.compact
    end
  end
end
