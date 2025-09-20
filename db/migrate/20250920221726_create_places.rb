class CreatePlaces < ActiveRecord::Migration[8.0]
  def change
    create_table :places do |t|
      t.string :name
      t.integer :kind
      t.string :country_code
      t.string :admin1_code
      t.integer :external_id, limit: 8
      t.float :lat
      t.float :lon
      t.integer :population, limit: 8
      t.references :parent, foreign_key: { to_table: :places }

      t.timestamps
    end
  end
end
