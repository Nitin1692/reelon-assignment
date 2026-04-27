module Api
  module V1
    class AssignmentsController < BaseController
      def index
        target_user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
        authorize_user_access!(target_user)

        scope = Assignment.where(user: target_user).includes(:project)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(assignment_type: params[:assignment_type]) if params[:assignment_type].present?

        assignments = paginate(scope.order(scheduled_at: :asc))
        render json: {
          assignments: assignments.map { |a| assignment_json(a) },
          meta: pagination_meta(assignments)
        }
      end

      def create
        target_user = params.dig(:assignment, :user_id).present? ?
          User.find(params.dig(:assignment, :user_id)) : current_user
        authorize_user_access!(target_user)

        assignment = Assignment.new(assignment_params.merge(user: target_user))
        if assignment.save
          render json: { assignment: assignment_json(assignment) }, status: :created
        else
          render json: { errors: assignment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        assignment = Assignment.find(params[:id])
        authorize_user_access!(assignment.user)
        if assignment.update(assignment_params)
          render json: { assignment: assignment_json(assignment) }
        else
          render json: { errors: assignment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def assignment_params
        params.require(:assignment).permit(
          :title, :description, :assignment_type, :scheduled_at,
          :ends_at, :location, :status, :notes, :project_id, :user_id
        )
      end

      def assignment_json(a)
        {
          id: a.id,
          title: a.title,
          description: a.description,
          assignment_type: a.assignment_type,
          scheduled_at: a.scheduled_at,
          ends_at: a.ends_at,
          location: a.location,
          status: a.status,
          notes: a.notes,
          user_id: a.user_id,
          project: a.project ? { id: a.project.id, title: a.project.title } : nil,
          created_at: a.created_at
        }
      end
    end
  end
end
