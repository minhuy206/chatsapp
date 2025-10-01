class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :user_identifier, presence: true

  def history
    messages.order(created_at: :asc)
  end
end