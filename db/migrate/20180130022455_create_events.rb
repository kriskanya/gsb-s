class CreateEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :events do |t|
      t.string :title
      t.string :dates
      t.string :rating
      t.string :city
      t.string :state
      t.string :hours
      t.text :description
      t.string :promoter
      t.string :location
      t.string :vendor_info

      t.timestamps
    end
  end
end
