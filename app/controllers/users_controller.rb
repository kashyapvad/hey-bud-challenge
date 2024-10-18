# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def new
    @user = User.new
    @organizations = Organization.all
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to login_path, notice: 'User account created successfully. Please log in.'
    else
      @organizations = Organization.all
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :organization_id)
  end
end
