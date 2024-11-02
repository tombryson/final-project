class AuthController < ApplicationController
  # skip_before_action :require_login, only: [:login, :auto_login]
  before_action :check_logged_in, only: [:index]
  before_action :authorize_request, only: [:user_is_authed]

  def index
  end

  def login
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
      token = encode_token(payload)
      session[:user_id] = user.id
      render json: { user: user, jwt: token, success: "Welcome back, #{user.first_name}" }
    else
      render json: { failure: "Log in failed! Username or password invalid!" }
    end
  end

  def auto_login
    if session_user
      render json: session_user
    else
      render json: { errors: "No User Logged In" }
    end
  end

  def user_is_authed
    render json: { message: "You are authorized" }
  end

  def check_logged_in
    redirect_to :root if session[:user_id].present?
  end

  private

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def decode_token(token)
    begin
      JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
    rescue JWT::DecodeError
      nil
    end
  end

  def authorize_request
    token = request.headers['Authorization']&.split(' ')&.last
    decoded_token = decode_token(token)

    if decoded_token
      @current_user = User.find(decoded_token['user_id'])
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end