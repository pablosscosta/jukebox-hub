# Closes parties past their expiration (6 h without activity), so they stop accepting guests and
# songs and their screens learn it. Runs every few minutes (config/recurring.yml).
class ExpirePartiesJob < ApplicationJob
  def perform
    Party.overdue.find_each { |party| Parties::End.call(party:) }
  end
end
