module Api
  module V1
    class AuthController < ActionController::API
      def register
        user = User.new(register_params)
        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user_json(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email]&.downcase)
        if user&.authenticate(params[:password])
          unless user.active?
            return render json: { error: "Account is deactivated" }, status: :unauthorized
          end
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user_json(user) }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def me
        token = request.headers["Authorization"]&.split(" ")&.last
        decoded = JsonWebToken.decode(token)
        user = User.find(decoded[:user_id])
        render json: { user: user_json(user) }
      rescue => e
        render json: { error: e.message }, status: :unauthorized
      end

      private

      def register_params
        params.permit(:email, :name, :password, :password_confirmation, :role, :phone, :timezone)
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          phone: user.phone,
          timezone: user.timezone,
          avatar_url: user.avatar_url,
          created_at: user.created_at
        }
      end
    end
  end
end
