class UsersController < ApplicationController
  before_action :require_login, except: [:create]

  def create
    user = User.new(user_params)
    if user.save
      render json: { user: user_details(user), jwt: encode_token(user_id: user.id) }, status: :created
    else
      render json: { error: user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def index
    render json: [user_details(session_user)]
  end

  def show
    if params[:id].to_s != session_user.id.to_s
      return render json: { error: 'User not found.' }, status: :not_found
    end

    render json: [user_details(session_user), session_user.bookings]
  end

  private

  def user_params
    params.permit(:first_name, :last_name, :email, :password)
  end
end
