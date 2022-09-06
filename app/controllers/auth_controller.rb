class AuthController < ApplicationController
    skip_before_action :require_login, only: [:login, :auto_login]
    before_action :check_logged_in, only: [:index]

    def index
    end

    def login
      user = User.find_by(email: params[:email])
      if user && user.authenticate(params[:password])
          payload = {user_id: user.id}
          token = encode_token(payload)
          session[:user_id] = user.id
          render json: {user: user, jwt: token, success: "Welcome back, #{user.first_name}"}
      else
          render json: {failure: "Log in failed! Username or password invalid!"}
      end
    end
  
    def auto_login
      if session_user
        render json: session_user
      else
        render json: {errors: "No User Logged In"}
      end
    end
  
    def user_is_authed
      render json: {message: "You are authorized"}
    end

    def check_logged_in
        redirect_to :root if session[:user_id].present?
    end
  end