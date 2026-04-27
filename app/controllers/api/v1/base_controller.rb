module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!
      before_action :set_current_user

      attr_reader :current_user

      private

      def authenticate_user!
        header = request.headers["Authorization"]
        token = header&.split(" ")&.last
        raise "Missing token" if token.blank?
        decoded = JsonWebToken.decode(token)
        @current_user = User.find(decoded[:user_id])
        raise "Account is inactive" unless @current_user.active?
      rescue => e
        render json: { error: e.message }, status: :unauthorized
      end

      def set_current_user
        Current.user = @current_user
        Current.ip_address = request.remote_ip
      end

      def require_manager!
        render json: { error: "Manager access required" }, status: :forbidden unless current_user.manager?
      end

      def authorize_user_access!(target_user)
        return if current_user.admin?
        return if current_user == target_user
        return if current_user.can_manage?(target_user)
        render json: { error: "Access denied" }, status: :forbidden
      end

      def paginate(scope)
        scope.page(params[:page]).per(params[:per_page] || 20)
      end

      def pagination_meta(scope)
        {
          current_page: scope.current_page,
          total_pages: scope.total_pages,
          total_count: scope.total_count,
          per_page: scope.limit_value
        }
      end
    end
  end
end
