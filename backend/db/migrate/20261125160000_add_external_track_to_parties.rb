class AddExternalTrackToParties < ActiveRecord::Migration[8.1]
  def change
    change_table :parties, bulk: true do |t|
      # A song the host played straight from the Spotify app, outside the queue. The jukebox shows
      # it as playing and resumes the queue when it ends.
      t.jsonb :external_track
      # Last time the jukebox asked Spotify what is playing. Limits checks made when someone opens
      # the queue to one every few seconds per party.
      t.datetime :playback_checked_at
    end
  end
end
