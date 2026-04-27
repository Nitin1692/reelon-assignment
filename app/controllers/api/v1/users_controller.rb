module Api
  module V1
    class UsersController < BaseController
      def index
        users = if current_user.admin?
          User.all
        elsif current_user.manager?
          current_user.managed_professionals
        else
          User.none
        end

        users = users.where("name ILIKE ? OR email ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
        users = paginate(users.order(:name))

        render json: {
          users: users.map { |u| user_json(u) },
          meta: pagination_meta(users)
        }
      end

      def show
        user = User.find(params[:id])
        authorize_user_access!(user)
        render json: { user: user_json(user) }
      end

      def professionals
        require_manager!
        professionals = current_user.managed_professionals.order(:name)
        render json: { users: professionals.map { |u| user_json(u) } }
      end

      def assign_manager
        require_manager!
        professional = User.find(params[:professional_id])
        relationship = UserRelationship.find_or_initialize_by(
          manager: current_user,
          professional: professional
        )
        if relationship.save
          render json: { message: "#{professional.name} is now managed by #{current_user.name}" }
        else
          render json: { errors: relationship.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def remove_manager
        require_manager!
        professional = User.find(params[:professional_id])
        relationship = UserRelationship.find_by(manager: current_user, professional: professional)
        if relationship&.destroy
          render json: { message: "Relationship removed" }
        else
          render json: { error: "Relationship not found" }, status: :not_found
        end
      end

      private

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          phone: user.phone,
          timezone: user.timezone,
          avatar_url: user.avatar_url,
          active: user.active,
          created_at: user.created_at,
          managers: user.managers.map { |m| { id: m.id, name: m.name } }
        }
      end
    end
  end
end
