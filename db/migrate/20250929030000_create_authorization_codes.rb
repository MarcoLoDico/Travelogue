class CreateAuthorizationCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :authorization_codes do |t|
      t.string :code, null: false
      t.references :user, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: { to_table: :oauth_applications }
      t.string :redirect_uri, null: false
      t.string :scope
      t.string :nonce
      t.string :code_challenge
      t.string :code_challenge_method
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :authorization_codes, :code, unique: true
  end
end
