module Api
  module V1
    class TasksController < BaseController
      before_action :set_task, only: [:show, :update, :destroy, :complete]

      def index
        target_user = target_user_for_index
        return unless target_user

        scope = Task.where(user: target_user).includes(:created_by, :schedule_entry)

        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(task_type: params[:task_type]) if params[:task_type].present?
        scope = scope.where(priority: params[:priority]) if params[:priority].present?
        scope = scope.where(due_date: Date.parse(params[:from])..Date.parse(params[:to])) if params[:from].present? && params[:to].present?

        scope = scope.overdue if params[:overdue] == "true"

        tasks = paginate(scope.order(due_date: :asc, priority: :desc))

        render json: {
          tasks: tasks.map { |t| task_json(t) },
          meta: pagination_meta(tasks)
        }
      end

      def show
        authorize_user_access!(@task.user)
        render json: { task: task_json(@task) }
      end

      def create
        target_user = resolve_target_user
        return unless target_user

        task = Task.new(task_params.merge(
          user: target_user,
          created_by: current_user
        ))

        if task.save
          render json: { task: task_json(task) }, status: :created
        else
          render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize_user_access!(@task.user)
        if @task.update(task_params)
          render json: { task: task_json(@task) }
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize_user_access!(@task.user)
        @task.update!(status: "cancelled")
        render json: { message: "Task cancelled" }
      end

      def complete
        authorize_user_access!(@task.user)
        @task.complete!(current_user)
        render json: { task: task_json(@task) }
      end

      private

      def set_task
        @task = Task.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Task not found" }, status: :not_found
      end

      def task_params
        params.require(:task).permit(
          :title, :description, :task_type, :due_date, :due_time,
          :priority, :status, :schedule_entry_id, :user_id
        )
      end

      def target_user_for_index
        if params[:user_id].present?
          user = User.find(params[:user_id])
          authorize_user_access!(user)
          user
        else
          current_user
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
        nil
      end

      def resolve_target_user
        uid = params.dig(:task, :user_id)
        if uid.present?
          user = User.find(uid)
          unless current_user.can_manage?(user) || current_user == user
            render json: { error: "Access denied" }, status: :forbidden
            return nil
          end
          user
        else
          current_user
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
        nil
      end

      def task_json(task)
        {
          id: task.id,
          title: task.title,
          description: task.description,
          task_type: task.task_type,
          due_date: task.due_date,
          due_time: task.due_time,
          priority: task.priority,
          status: task.status,
          overdue: task.overdue?,
          completed_at: task.completed_at,
          user_id: task.user_id,
          created_by: task.created_by ? { id: task.created_by.id, name: task.created_by.name } : nil,
          schedule_entry_id: task.schedule_entry_id,
          created_at: task.created_at,
          updated_at: task.updated_at
        }
      end
    end
  end
end
