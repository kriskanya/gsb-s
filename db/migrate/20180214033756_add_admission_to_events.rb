class AddAdmissionToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :admission, :string
  end
end
