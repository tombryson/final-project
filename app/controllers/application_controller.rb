class ApplicationController < ActionController::API
    def encode_token(payload)
        JWT.encode(payload.merge(exp: 24.hours.from_now.to_i), Rails.application.secret_key_base, 'HS256')
    end

    def session_user
        return @current_user if defined?(@current_user)

        token = request.headers['Authorization']&.split(' ')&.last
        return nil if token.blank?

        payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')[0]
        @current_user = User.find_by(id: payload['user_id'])
    rescue JWT::DecodeError
        nil
    end

    def require_login
        render json: { error: 'Please sign in to continue.' }, status: :unauthorized unless session_user
    end

    def user_details(user)
        user.as_json(only: [:id, :first_name, :last_name, :email])
    end
end
