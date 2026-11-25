module QueueItems
  # Decides the order in which pending songs will play. It is a pure function (no database, no
  # clock), so the rule is easy to test and the order is always recalculated from the facts
  # instead of being stored and kept in sync.
  #
  # The rule: songs play in arrival order, but nobody gets 3 songs in a row while someone else has
  # a song waiting. When the last 2 songs are from the same person, the earliest song from someone
  # else jumps ahead. If only that person has songs waiting, theirs keep playing.
  class PlayOrder
    MAX_IN_A_ROW = 2

    # pending: songs waiting, in arrival order (anything that responds to #participant_id).
    # recent_participant_ids: who had the songs that started last, most recent first.
    def self.call(...) = new(...).call

    def initialize(pending:, recent_participant_ids: [])
      @remaining = pending.to_a.dup
      @history = recent_participant_ids.first(MAX_IN_A_ROW).reverse
    end

    def call
      order = []
      until @remaining.empty?
        song = next_song
        @remaining.delete(song)
        order << song
        @history = (@history + [song.participant_id]).last(MAX_IN_A_ROW)
      end
      order
    end

    private

    def next_song
      streak_owner = @history.first if @history.size == MAX_IN_A_ROW && @history.uniq.size == 1
      return @remaining.first unless streak_owner

      @remaining.find { |song| song.participant_id != streak_owner } || @remaining.first
    end
  end
end
