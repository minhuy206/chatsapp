class AddModelComparisonSupport < ActiveRecord::Migration[8.0]
  def change
    add_column :conversations, :comparison_mode, :boolean, default: false, null: false
    add_column :conversations, :model_a, :string
    add_column :conversations, :model_b, :string

    add_column :messages, :model_version, :string
    add_column :messages, :comparison_vote, :integer, default: 0

    add_index :conversations, :comparison_mode
    add_index :messages, :comparison_vote
  end
end