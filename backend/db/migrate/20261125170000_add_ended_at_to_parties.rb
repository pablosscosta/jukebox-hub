class AddEndedAtToParties < ActiveRecord::Migration[8.1]
  def change
    # When the party ended: the data of ended parties is deleted a while later (ADR 0002).
    add_column :parties, :ended_at, :datetime
    add_index :parties, :ended_at, where: "status = 'ended'"

    reversible do |dir|
      dir.up { execute "UPDATE parties SET ended_at = updated_at WHERE status = 'ended'" }
    end
  end
end
