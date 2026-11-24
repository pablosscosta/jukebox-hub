class AddProductToHosts < ActiveRecord::Migration[8.1]
  def change
    # Spotify plan ("premium", "free", ...), read from the profile on every login. Controlling
    # playback through the API requires Premium.
    add_column :hosts, :product, :string
  end
end
