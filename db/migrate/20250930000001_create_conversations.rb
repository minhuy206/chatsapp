class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.string :user_identifier, null: false
      t.string :title
      t.timestamps
    end

    add_index :conversations, :user_identifier
  end
end