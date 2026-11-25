# Parties are ephemeral (ADR 0002): a day after a party ends, its guests and queue are deleted too.
class DeleteEndedPartiesJob < ApplicationJob
  def perform
    Party.ended_long_ago.find_each(&:destroy!)
  end
end
