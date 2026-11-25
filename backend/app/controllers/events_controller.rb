# GET /parties/:party_id/events: Server-Sent Events stream (ADR 0004).
#
# The browser's EventSource can't send an Authorization header, so the stream carries no data at
# all, only notices like "queue_changed": the screen then reloads the queue through the regular API
# with its own token. That's why this endpoint needs no token.
#
# All database work happens here, before streaming starts. The stream itself (PartyEvents::Stream)
# is a response body that Puma writes out bit by bit and that never touches the database. That's
# on purpose: ActionController::Live runs the action in a second thread that shares the request's
# database connection, and queries made while streaming ended up using one connection from two
# threads at once.
class EventsController < ApplicationController
  include PartyScoped

  # Streams are closed after a while and EventSource reconnects by itself. That frees the Puma
  # thread now and then and keeps proxies from dropping a connection that looks idle. In
  # development both are much shorter: reloading changed code waits for every open request to
  # finish, so an open stream holds new requests until it closes.
  HEARTBEAT = Rails.env.development? ? 5.seconds : 15.seconds
  MAX_LIFETIME = Rails.env.development? ? 10.seconds : 5.minutes

  def show
    prepare_stream_headers
    self.response_body = PartyEvents::Stream.new(
      party_id: @party.id, ended: !@party.open?, heartbeat: HEARTBEAT, lifetime: MAX_LIFETIME,
      on_heartbeat: -> { check_spotify_if_due(@party.id) }
    )
  end

  private

  def prepare_stream_headers
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    # Tells proxies like nginx not to hold the events in a buffer.
    response.headers["X-Accel-Buffering"] = "no"
  end

  # While someone is watching, the jukebox looks at Spotify (at most once every 20 s per party).
  # It runs in a thread of its own, wrapped by the Rails executor, and isn't waited for: the
  # stream must not touch the database, and a slow call to Spotify must not hold it.
  def check_spotify_if_due(party_id)
    return if @last_check && @last_check > Playback::CheckIfDue::INTERVAL.ago

    @last_check = Time.current
    Thread.new do
      Rails.application.executor.wrap { Playback::CheckIfDue.call(Party.find(party_id)) }
    rescue StandardError => e
      Rails.logger.warn("[events] Spotify check failed for party #{party_id}: #{e.class}")
    end
  end
end
