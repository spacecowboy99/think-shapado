class LinkedController < ApplicationController
  def start
    if logged_in? && params[:merge]
      merge_token = cookies[:merge_token] = ActiveSupport::SecureRandom.hex(12)
      current_user.set({:merge_token => merge_token})
    end

    rtoken = myclient.request_token.token
    rsecret = myclient.request_token.secret
   
  end

  def callback
    access_token = nil
    begin
      access_token = client.web_server.get_access_token(
        params[:code], :redirect_uri => oauth_callback_url
      )
    rescue OAuth2::HTTPError
    end

    if access_token.nil?
      flash[:notice] = "Cannot authenticate you"
      redirect_to root_path
      return
    end

    user_json = access_token.get('/me')
    # in reality you would at this point store the access_token.token value as well as
    # any user info you wanted

    user_json = JSON.parse(user_json)
    atts = {:facebook_id => user_json["id"],
            :facebook_profile => user_json["link"]}

    @user = User.first(:facebook_id => user_json["id"])
    if @user.nil?
      if logged_in? && (token = cookies.delete("merge_token"))
        @user = User.first(:merge_token => token)

        @user.set(atts)
        @user.facebook_id = user_json["id"]
        @user.facebook_profile = user_json["link"]
      else
        @user = User.first(:email => user_json["email"])
      end

      if @user.nil?
        atts[:birthday] = Time.zone.parse(user_json["birthday"]) if user_json["birthday"]
        @user = User.create(atts.merge(
                              :website => user_json["link"],
                              :name => "#{user_json["first_name"]} #{user_json["last_name"]}",
                              :login => user_json["name"],
                              :timezone => ActiveSupport::TimeZone[user_json["timezone"]],
                              :email => user_json["email"]
                            ))

        if @user.errors.on(:login)
          @user.login = "#{@user.login}_fb"
          @user.save
        end
      elsif @user.facebook_id.nil?
        @user.set(atts)
        @user.facebook_id = user_json["id"]
        @user.facebook_profile = user_json["link"]
      end
    end

    warden.set_user(@user, :scope => "user")
    @user.remember_me!
    after_authentication(@user)

    sign_in_and_redirect(:user, @user, true)
  end

  protected

  def myclient
    @myclient = LinkedIn::Client.new(AppConfig.linked["key"], AppConfig.linked["secret"])
  end

  def consumer
    @consumer = OAuth::Consumer.new( 
      AppConfig.linked["key"],AppConfig.linked["secret"], {:site=>"https://api.linkedin.com/"}
    )
  end




end
