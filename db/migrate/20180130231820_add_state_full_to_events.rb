class AddStateFullToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :state_full, :string
  end
end
