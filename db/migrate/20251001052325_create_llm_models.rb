class CreateLlmModels < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_models do |t|
      t.string :name, null: false
      t.string :provider, null: false
      t.boolean :enabled, default: true, null: false
      t.jsonb :config, default: {}

      t.timestamps
    end

    add_index :llm_models, :name, unique: true
    add_index :llm_models, :provider
    add_index :llm_models, :enabled
  end
end
