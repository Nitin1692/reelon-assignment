module Api
  module V1
    class ProjectsController < BaseController
      def index
        scope = Project.includes(:created_by, :assignments)
        scope = scope.where(status: params[:status]) if params[:status].present?
        projects = paginate(scope.order(created_at: :desc))

        render json: {
          projects: projects.map { |p| project_json(p) },
          meta: pagination_meta(projects)
        }
      end

      def show
        project = Project.find(params[:id])
        render json: { project: project_json(project, detailed: true) }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Project not found" }, status: :not_found
      end

      def create
        project = Project.new(project_params.merge(created_by: current_user))
        if project.save
          render json: { project: project_json(project) }, status: :created
        else
          render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        project = Project.find(params[:id])
        if project.update(project_params)
          render json: { project: project_json(project) }
        else
          render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def project_params
        params.require(:project).permit(:title, :description, :starts_at, :ends_at, :status, :category)
      end

      def project_json(project, detailed: false)
        json = {
          id: project.id,
          title: project.title,
          description: project.description,
          starts_at: project.starts_at,
          ends_at: project.ends_at,
          status: project.status,
          category: project.category,
          created_by: { id: project.created_by.id, name: project.created_by.name },
          created_at: project.created_at
        }
        json[:assignments] = project.assignments.map { |a| { id: a.id, title: a.title, user_id: a.user_id } } if detailed
        json
      end
    end
  end
end
