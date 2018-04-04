class AddLocationInfoToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :location_street, :string
    add_column :events, :location_city, :string
    add_column :events, :location_state, :string
    add_column :events, :location_zip, :string
  end
end


