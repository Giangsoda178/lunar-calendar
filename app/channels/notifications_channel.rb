# frozen_string_literal: true

class NotificationsChannel < ApplicationCable::Channel
  class << self
    def stream_name_for(user_id)
      user_id.present? ? "notifications:#{user_id}" : "notifications"
    end
  end

  def subscribed
    stream_from self.class.stream_name_for(params[:user_id])
  end

  def unsubscribed
    # Cleanup when channel is unsubscribed
  end
end
