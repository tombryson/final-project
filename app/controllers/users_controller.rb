class UsersController < ApplicationController

  def create
    user = User.create(first_name: params[:first_name], last_name: params[:last_name], email: params[:email], password: params[:password]) 
    if user.valid?
        payload = {user_id: user.id}
        token = encode_token(payload)
        puts token
        render json: {user: user, jwt: token}
    else
        render json: {errors: user.errors.full_messages}, status: :not_acceptable
    end
  end

  def index
    @users = User.all
    render json: @users
  end

  def show
    user_id = params[:id]
    @user = User.find_by_id(user_id)
    puts @user
    user_data = []
    @bookings = @user.bookings
    puts @bookings
    render json: user_data.push(@user, @bookings)
  end

  private 

  def user_params
    params.permit(:first_name, :last_name, :email, :password)
  end
end
