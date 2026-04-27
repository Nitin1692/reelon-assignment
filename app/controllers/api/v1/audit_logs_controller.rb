module Api
  module V1
    class AuditLogsController < BaseController
      def index
        scope = AuditLog.includes(:user).recent

        if params[:auditable_type].present? && params[:auditable_id].present?
          record = params[:auditable_type].constantize.find(params[:auditable_id])
          authorize_user_access!(record.try(:user) || record.try(:created_by))
          scope = scope.for_record(params[:auditable_type], params[:auditable_id])
        elsif current_user.manager? || current_user.admin?
          scope = scope.where(auditable_type: "ScheduleEntry")
                       .where(
                         auditable_id: ScheduleEntry.for_user(
                           current_user.admin? ? User.all.select(:id) : current_user.managed_professionals.select(:id)
                         ).select(:id)
                       )
        else
          scope = scope.where(auditable_type: "ScheduleEntry",
                              auditable_id: ScheduleEntry.for_user(current_user.id).select(:id))
        end

        logs = paginate(scope)

        render json: {
          audit_logs: logs.map { |l| log_json(l) },
          meta: pagination_meta(logs)
        }
      end

      private

      def log_json(log)
        {
          id: log.id,
          auditable_type: log.auditable_type,
          auditable_id: log.auditable_id,
          action: log.action,
          user: log.user ? { id: log.user.id, name: log.user.name } : nil,
          changes: log.changes_hash,
          created_at: log.created_at
        }
      end
    end
  end
end
