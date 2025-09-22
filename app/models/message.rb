class Message < ApplicationRecord
  belongs_to :conversation

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }

  scope :by_creation_order, -> { order(:created_at) }
  scope :user_messages, -> { where(role: "user") }
  scope :assistant_messages, -> { where(role: "assistant") }

  def user_message?
    role == "user"
  end

  def assistant_message?
    role == "assistant"
  end

  def formatted_created_at
    created_at.strftime("%I:%M %p")
  end
end
