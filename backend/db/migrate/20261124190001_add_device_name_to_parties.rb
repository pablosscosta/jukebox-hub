class AddDeviceNameToParties < ActiveRecord::Migration[8.1]
  def change
    # Name of the device when the party was created, so the UI can show where the music plays
    # without asking Spotify again. The temporary default fills rows that already exist; new
    # parties must always send a name.
    #
    # Two separate statements on purpose: with `change_table bulk: true` Rails merges them into
    # one ALTER, and the rollback drops the column before resetting its default, which fails.
    # rubocop:disable Rails/BulkChangeTable
    add_column :parties, :device_name, :string, null: false, default: ""
    change_column_default :parties, :device_name, from: "", to: nil
    # rubocop:enable Rails/BulkChangeTable
  end
end
