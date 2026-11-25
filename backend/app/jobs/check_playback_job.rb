# Runs near the end of each song and asks Spotify what is really happening (Playback::Reconcile),
# instead of trusting the clock: the host may have paused, or played something else.
#
# The first check runs a few seconds before the song should end, while it is still playing. Seeing
# the song about to end, the job checks again right after it, with ending: true.
class CheckPlaybackJob < ApplicationJob
  ENDING_WINDOW = 5.seconds
  # A paused song may stay paused for a while: look again later, without calling Spotify too often.
  PAUSED_RECHECK = 30.seconds

  retry_on Spotify::Error, wait: 15.seconds, attempts: 4
  discard_on SpotifyAuth::ReauthenticationRequired

  def self.schedule_for(item)
    schedule(item.party_id, "item:#{item.id}", wait: item.duration_ms.fdiv(1000).seconds - ENDING_WINDOW)
  end

  # Schedules the next check for what is playing, from how much of it is left.
  def self.schedule_after(party, watch_key, playback)
    return schedule(party.id, watch_key, wait: PAUSED_RECHECK) unless playback.playing

    remaining = playback.remaining_ms.fdiv(1000).seconds
    if remaining > ENDING_WINDOW
      schedule(party.id, watch_key, wait: remaining - ENDING_WINDOW)
    else
      schedule(party.id, watch_key, wait: remaining + 1.second, ending: true)
    end
  end

  def self.schedule(party_id, watch_key, wait:, ending: false)
    set(wait: [wait, 0.seconds].max).perform_later(party_id, watch_key, ending)
  end

  def perform(party_id, watch_key, ending = false) # rubocop:disable Style/OptionalBooleanParameter
    party = Party.find_by(id: party_id)
    # The party ended or already moved on (skip, another check, the host's song): nothing to do.
    return unless party&.open? && party.playback_watch_key == watch_key

    spotify = Spotify::ApiClient.new(access_token: SpotifyAuth::FreshAccessToken.call(party.host))
    result = Playback::Reconcile.call(party:, spotify:, ending:)
    self.class.schedule_after(party, watch_key, result.playback) if result.status == :unchanged
  end
end
