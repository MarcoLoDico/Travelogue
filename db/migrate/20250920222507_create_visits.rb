class CreateVisits < ActiveRecord::Migration[8.0]
  def change
    create_table :visits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :place, null: false, foreign_key: true
      t.date :visited_on
      t.datetime :arrived_at
      t.datetime :departed_at
      t.text :notes
      t.float :lat
      t.float :lon
      t.string :source

      t.timestamps
    end
  end
end
