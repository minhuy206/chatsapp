class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.string :title
      t.string :ai_model

      t.timestamps
    end
  end
end
