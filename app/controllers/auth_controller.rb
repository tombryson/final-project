class AuthController < ApplicationController
  before_action :require_login, only: [:auto_login, :user_is_authed]

  def login
    user = User.where('LOWER(email) = ?', params[:email].to_s.strip.downcase).order(:id).first
    if user && user.authenticate(params[:password].to_s)
      render json: { user: user_details(user), jwt: encode_token(user_id: user.id) }
    else
      render json: { error: 'Email or password is incorrect.' }, status: :unauthorized
    end
  end

  def auto_login
    render json: user_details(session_user)
  end

  def user_is_authed
    render json: { message: 'You are authorized' }
  end
end
