class UsersController < ApplicationController
  before_filter :login_required, :only => [:edit, :update, :follow]
  tabs :default => :users

  subtabs :index => [[:reputation, "reputation"],
                     [:newest, "created_at desc"],
                     [:oldest, "created_at asc"],
                     [:name, "login asc"]]

  def index
    set_page_title(t("users.index.title"))
    options =  {:per_page => params[:per_page]||24,
               :order => current_order,
               :page => params[:page] || 1}
    options[:login] = /^#{Regexp.escape(params[:q])}/ if params[:q]

    if options[:order] == "reputation"
      options[:order] = "membership_list.#{current_group.id}.reputation desc"
    end

    @users = current_group.users(options)

    respond_to do |format|
      format.html
      format.json {
        except = [:password, :password_confirmation, :crypted_password,
                  :encrypted_password, :password_salt, :salt, :email, :identity_url,
                  :default_subtab, :ip, :language_filter ]
        render :json => @users.to_json(:except => except)
      }
      format.js {
        html = render_to_string(:partial => "user", :collection  => @users)
        pagination = render_to_string(:partial => "shared/pagination", :object => @users,
                                      :format => "html")
        render :json => {:html => html, :pagination => pagination }
      }
    end

  end

  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    @user = User.new
    @user.safe_update(%w[login email name password_confirmation password preferred_languages
                         language timezone identity_url bio hide_country], params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      @user.localize(request.remote_ip)
      flash[:notice] = t("flash_notice", :scope => "users.create")
      sign_in_and_redirect(:user, @user) # !! now logged in
    else
      flash[:error]  = t("flash_error", :scope => "users.create")
      render :action => 'new'
    end
  end

  def show
    @user = User.find_by_login_or_id(params[:id])
    raise PageNotFound unless @user
    @questions = @user.questions.paginate(:page=>params[:questions_page],
                                          :order => "votes_average desc, created_at desc",
                                          :per_page => 10,
                                          :group_id => current_group.id,
                                          :banned => false)
    @answers = @user.answers.paginate(:page=>params[:answers_page],
                                      :order => "votes_average desc, created_at desc",
                                      :group_id => current_group.id,
                                      :per_page => 10,
                                      :banned => false)

    @badges = @user.badges.paginate(:page => params[:badges_page],
                                    :group_id => current_group.id,
                                    :per_page => 25)

    @favorites = @user.favorites.paginate(:page => params[:favorites_page],
                                          :per_page => 25,
                                          :group_id => current_group.id)

    @favorite_questions = Question.find(@favorites.map{|f| f.question_id })

    add_feeds_url(url_for(:format => "atom"), t("feeds.user"))

    @user.viewed_on!(current_group) if @user != current_user && !is_bot?

    respond_to do |format|
      format.html
      format.atom
      format.json {
        except = [:password, :password_confirmation, :crypted_password,
                  :encrypted_password, :password_salt, :salt, :email, :identity_url,
                  :default_subtab, :ip, :language_filter ]
        render :json => @user.to_json(:except => except)
      }
    end
  end

  def edit
    @user = current_user
  end

  def update
    if params[:id] == 'login' && params[:user].nil? # HACK for facebook-connectable
      redirect_to root_path
      return
    end

    @user = current_user

    if params[:current_password] && @user.valid_password?(params[:current_password])
      @user.encrypted_password = ""
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end

    @user.safe_update(%w[login email name language timezone preferred_languages
                         notification_opts bio hide_country website], params[:user])

    if params[:user]["birthday(1i)"]
      @user.birthday = build_date(params[:user], "birthday")
    end

    Magent.push("actors.judge", :on_update_user, @user.id, current_group.id)

    preferred_tags = params[:user][:preferred_tags]
    if @user.valid? && @user.save
      @user.add_preferred_tags(preferred_tags, current_group) if preferred_tags
      redirect_to root_path
    else
      render :action => "edit"
    end
  end

  def change_preferred_tags
    @user = current_user
    if params[:tags]
      if params[:opt] == "add"
        @user.add_preferred_tags(params[:tags], current_group) if params[:tags]
      elsif params[:opt] == "remove"
        @user.remove_preferred_tags(params[:tags], current_group)
      end
    end

    respond_to do |format|
      format.html {redirect_to questions_path}
    end
  end

  def follow
    @user = User.find_by_login_or_id(params[:id])
    current_user.add_friend(@user)

    flash[:notice] = t("flash_notice", :scope => "users.follow", :user => @user.login)

    if @user.notification_opts.activities
      Notifier.deliver_follow(current_user, @user)
    end

    Magent.push("actors.judge", :on_follow, current_user.id, @user.id, current_group.id)

    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
    end
  end

  def unfollow
    @user = User.find_by_login_or_id(params[:id])
    current_user.remove_friend(@user)

    flash[:notice] = t("flash_notice", :scope => "users.unfollow", :user => @user.login)

    Magent.push("actors.judge", :on_unfollow, current_user.id, @user.id, current_group.id)

    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
    end
  end

  def autocomplete_for_user_login
    @users = User.all( :limit => params[:limit] || 20,
                       :fields=> 'login',
                       :login =>  /^#{Regexp.escape(params[:prefix].to_s.downcase)}.*/,
                       :order => "login desc")
    respond_to do |format|
      format.json {render :json=>@users}
    end
  end
end


