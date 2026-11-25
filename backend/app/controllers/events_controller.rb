# GET /parties/:party_id/events: Server-Sent Events stream (ADR 0004).
#
# The browser's EventSource can't send an Authorization header, so the stream carries no data at
# all, only notices like "queue_changed": the screen then reloads the queue through the regular API
# with its own token. That's why this endpoint needs no token.
class EventsController < ApplicationController
  include ActionController::Live
  include PartyScoped

  HEARTBEAT = 15.seconds
  # Streams are closed after a while and EventSource reconnects by itself. That frees the Puma
  # thread now and then and keeps proxies from dropping a connection that looks idle. In
  # development it is much shorter: reloading changed code waits for every open request to finish,
  # and an open stream would hold every new request until then.
  MAX_LIFETIME = Rails.env.development? ? 30.seconds : 5.minutes

  def show
    prepare_stream
    return send_event("party_ended") unless @party.open?

    stream_events
  rescue ActionController::Live::ClientDisconnected, IOError
    # The phone left the page or lost the connection: nothing to clean up besides the subscription.
  ensure
    response.stream.close
  end

  private

  def prepare_stream
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    # Tells proxies like nginx not to hold the events in a buffer.
    response.headers["X-Accel-Buffering"] = "no"
  end

  def stream_events
    listener = PartyEvents::Listener.instance
    queue = listener.subscribe(@party.id)
    send_event("connected")
    relay(queue)
  ensure
    listener&.unsubscribe(@party.id, queue) if queue
  end

  # Writes each notice as it arrives, or a heartbeat when none came, until the stream gets old.
  def relay(queue)
    deadline = MAX_LIFETIME.from_now
    while Time.current < deadline
      event = queue.pop(timeout: HEARTBEAT.to_i)
      event ? send_event(event) : heartbeat
      break if event == "party_ended"
    end
  end

  def send_event(event)
    response.stream.write("event: #{event}\ndata: {}\n\n")
  end

  # A comment line keeps the connection alive. While someone is watching, it's also when the
  # jukebox looks at Spotify (at most once every 20 s per party).
  def heartbeat
    Playback::CheckIfDue.call(@party.reload)
    response.stream.write(": heartbeat\n\n")
  end
end
