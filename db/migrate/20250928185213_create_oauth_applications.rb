class CreateOauthApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :oauth_applications do |t|
      t.string :name
      t.string :uid
      t.string :secret
      t.text :redirect_uri
      t.text :scopes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
