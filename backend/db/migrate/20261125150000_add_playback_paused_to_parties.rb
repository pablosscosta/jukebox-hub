class AddPlaybackPausedToParties < ActiveRecord::Migration[8.1]
  def change
    # True when the host played something else on Spotify: the jukebox stops and waits for them to
    # press "Tocar", instead of fighting over the player.
    add_column :parties, :playback_paused, :boolean, null: false, default: false
  end
end
