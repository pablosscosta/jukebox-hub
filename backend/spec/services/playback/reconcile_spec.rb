require "rails_helper"

RSpec.describe Playback::Reconcile do
  let(:party) { create(:party) }
  let(:spotify) { Spotify::ApiClient.new(access_token: "host-access-token") }
  let!(:current) { create(:queue_item, :playing, participant: create(:participant, party:)) }
  let!(:next_song) { create(:queue_item, participant: create(:participant, party:)) }

  before { stub_spotify_play }

  def reconcile(ending: false)
    described_class.call(party:, spotify:, ending:)
  end

  describe "while a song from the queue plays" do
    it "changes nothing while it is still on" do
      stub_spotify_playback(track_id: current.track_id, progress_ms: 60_000)

      expect(reconcile.status).to eq(:unchanged)
      expect(current.reload).to be_playing
    end

    it "plays the next song once it finished" do
      stub_spotify_playback(track_id: current.track_id, playing: false, progress_ms: 0)

      reconcile

      expect([current.reload, next_song.reload].map(&:status)).to eq(%w[played playing])
    end

    it "plays the next song after the end, even if Spotify's autoplay started another one" do
      stub_spotify_playback(track_id: "autoplaySuggestion0000")

      reconcile(ending: true)

      expect(next_song.reload).to be_playing
    end

    it "follows a song the host played straight from Spotify, instead of fighting it" do
      stub_spotify_playback(track_id: "hostChoice000000000000", progress_ms: 10_000)

      reconcile

      expect([current.reload, next_song.reload].map(&:status)).to eq(%w[played pending])
      expect(party.reload.external_track).to include("trackId" => "hostChoice000000000000",
                                                     "title" => "Garota de Ipanema")
    end

    it "checks again near the end of the host's song" do
      stub_spotify_playback(track_id: "hostChoice000000000000", progress_ms: 10_000, duration_ms: 200_000)

      freeze_time do
        reconcile

        expect(CheckPlaybackJob).to have_been_enqueued
          .with(party.id, "track:hostChoice000000000000", false).at(185.seconds.from_now)
      end
    end

    it "trusts nothing in the first seconds, while Spotify may still report the old state" do
      current.update!(started_at: 2.seconds.ago)
      stub_spotify_playback

      expect(reconcile.status).to eq(:unchanged)
      expect(current.reload).to be_playing
      expect(party.reload).not_to be_playback_paused
    end

    it "waits for the host when Spotify stopped in the middle of the song" do
      stub_spotify_playback

      reconcile

      expect(party.reload).to be_playback_paused
      expect(next_song.reload).to be_pending
    end
  end

  describe "while the host's own song plays" do
    before do
      current.played!
      party.update!(external_track: { trackId: "hostChoice000000000000", title: "Have a Nice Day" })
    end

    it "changes nothing while it is still on" do
      stub_spotify_playback(track_id: "hostChoice000000000000", progress_ms: 60_000)

      expect(reconcile.status).to eq(:unchanged)
      expect(party.reload.playback_state).to eq("external")
    end

    it "resumes the queue when it ends" do
      stub_spotify_playback(track_id: "albumNextTrack00000000")

      reconcile(ending: true)

      expect(next_song.reload).to be_playing
      expect(party.reload.external_track).to be_nil
    end

    it "follows the next song the host plays before that" do
      stub_spotify_playback(track_id: "anotherHostChoice00000", progress_ms: 1_000)

      reconcile

      expect(party.reload.external_track["trackId"]).to eq("anotherHostChoice00000")
      expect(next_song.reload).to be_pending
    end
  end
end
