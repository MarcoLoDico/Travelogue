class DropOauthTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :access_tokens, if_exists: true
    drop_table :oauth_applications, if_exists: true
  end

  def down
    create_table :oauth_applications do |t|
      t.string :name
      t.string :uid
      t.string :secret
      t.text :redirect_uri
      t.text :scopes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    create_table :access_tokens do |t|
      t.string :token
      t.string :refresh_token
      t.datetime :expires_at
      t.text :scopes
      t.references :application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
