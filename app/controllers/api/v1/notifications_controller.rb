module Api
  module V1
    class NotificationsController < BaseController
      def index
        notifications = current_user.notifications
        notifications = notifications.unread if params[:unread] == "true"
        notifications = paginate(notifications.recent)

        render json: {
          notifications: notifications.map { |n| notification_json(n) },
          unread_count: current_user.notifications.unread.count,
          meta: pagination_meta(notifications)
        }
      end

      def mark_read
        notification = current_user.notifications.find(params[:id])
        notification.mark_read!
        render json: { notification: notification_json(notification) }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Notification not found" }, status: :not_found
      end

      def mark_all_read
        current_user.notifications.unread.update_all(read: true)
        render json: { message: "All notifications marked as read" }
      end

      private

      def notification_json(n)
        {
          id: n.id,
          title: n.title,
          body: n.body,
          notification_type: n.notification_type,
          read: n.read,
          notifiable_type: n.notifiable_type,
          notifiable_id: n.notifiable_id,
          created_at: n.created_at
        }
      end
    end
  end
end
