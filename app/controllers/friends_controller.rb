class FriendsController < ApplicationController

  def show
    @user = current_user
    raise PageNotFound unless @user
  end

  protected
  def check_page_permissions
    if !logged_in?
      login_required
      return false
    end
  end
end
