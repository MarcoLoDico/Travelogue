class AddPasswordDigestToUsersAndDropOneTimeCodes < ActiveRecord::Migration[8.0]
  def change
    # Add password_digest for has_secure_password
    add_column :users, :password_digest, :string, null: false, default: ""

    # Drop one_time_codes table (no longer needed with password auth)
    drop_table :one_time_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code
      t.datetime :expires_at
      t.boolean :used
      t.timestamps
    end
  end
end
