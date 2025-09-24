class Message < ApplicationRecord
  belongs_to :conversation

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  validates :comparison_vote, inclusion: { in: [ 0, 1, 2 ] }, allow_nil: true

  scope :by_creation_order, -> { order(:created_at) }
  scope :user_messages, -> { where(role: "user") }
  scope :assistant_messages, -> { where(role: "assistant") }
  scope :voted, -> { where.not(comparison_vote: [ nil, 0 ]) }

  def user_message?
    role == "user"
  end

  def assistant_message?
    role == "assistant"
  end

  def formatted_created_at
    created_at.strftime("%I:%M %p")
  end

  def voted?
    comparison_vote.present? && comparison_vote != 0
  end

  def vote_for_model_a?
    comparison_vote == 1
  end

  def vote_for_model_b?
    comparison_vote == 2
  end

  def vote_tie?
    comparison_vote == 0 && voted?
  end
end
