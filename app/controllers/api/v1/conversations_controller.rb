module Api
  module V1
    class ConversationsController < ApplicationController
      # GET /api/v1/conversations
      def index
        conversations = Conversation
          .where(user_identifier: current_user_identifier)
          .order(created_at: :desc)
          .limit(50)

        render json: {
          conversations: conversations.map { |c|
            {
              id: c.id,
              title: c.title || "Conversation #{c.id}",
              created_at: c.created_at,
              message_count: c.messages.count
            }
          }
        }
      end

      # GET /api/v1/conversations/:id
      def show
        conversation = Conversation.find(params[:id])

        render json: {
          conversation: {
            id: conversation.id,
            title: conversation.title,
            created_at: conversation.created_at
          },
          messages: conversation.history.map { |msg|
            {
              id: msg.id,
              role: msg.role,
              content: msg.content,
              model_used: msg.model_used,
              tokens_used: msg.tokens_used,
              created_at: msg.created_at
            }
          }
        }
      end
    end
  end
end