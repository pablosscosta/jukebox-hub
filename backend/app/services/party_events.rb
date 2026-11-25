# Tells the open screens of a party that something changed, through Postgres NOTIFY on a single
# channel. Each Puma process has one Listener that forwards the notice to its SSE streams (ADR 0004).
#
# The notice carries no data, only what happened ("queue_changed", "party_ended"): each screen then
# reloads the queue through the regular API, with its own token.
module PartyEvents
  CHANNEL = "party_events".freeze

  module_function

  # Sent inside the current transaction: Postgres only delivers it on commit (nothing goes out if
  # the change is rolled back) and merges identical notices sent in the same transaction, so a skip
  # that changes several rows still sends just one.
  def publish(party_id, event)
    payload = { partyId: party_id, event: }.to_json
    # execute (not exec_query): pg_notify returns void, a type Active Record has nothing to map to.
    sql = ActiveRecord::Base.sanitize_sql_array(["SELECT pg_notify(?, ?)", CHANNEL, payload])
    ActiveRecord::Base.connection.execute(sql)
  end
end
