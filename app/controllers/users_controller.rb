class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new_modal create_modal new create]

  def new_modal
    @user = User.new
  end

  def create_modal
    @user = User.new(user_params)
    if @user.save
      login(user_params[:email], user_params[:password])
    else
      flash.now[:error] = I18n.t('flash_messages.users.registration_failure')
    end
    respond_to do |format|
      format.turbo_stream
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      login(user_params[:email], user_params[:password])
      redirect_to edit_profile_path, status: :see_other, notice: I18n.t('flash_messages.users.registration_success')
    else
      flash.now[:error] = I18n.t('flash_messages.users.registration_failure')
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password)
  end
end
