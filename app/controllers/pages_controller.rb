class PagesController < ApplicationController
  before_filter :login_required, :except => [:show]
  before_filter :moderator_required, :only => [:index]

  before_filter :check_page_permissions, :only => [:new, :create, :edit, :update, :destroy]

  layout :set_layout

  tabs :default => :pages

  # GET /pages
  # GET /pages.json
  def index
    @pages = current_group.pages.paginate(:page => params[:page], :per_page => params[:per_page] || 25)

    respond_to do |format|
      format.html # index.html.haml
      format.json  { render :json => @pages }
    end
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
    @page = current_group.pages.by_slug(params[:id], :language => Page.current_language) || current_group.pages.by_slug(params[:id])

    respond_to do |format|
      format.html do
        if @page.nil? && params[:create]
          @page = Page.new(:title => params[:title], :slug => params[:id])
          render :action => "new"
        else
          render
        end
      end
      format.json  { render :json => @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.json
  def new
    @page = Page.new

    respond_to do |format|
      format.html # new.html.haml
      format.json  { render :json => @page }
    end
  end

  # GET /pages/1/edit
  def edit
  end

  # POST /pages
  # POST /pages.json
  def create
    @page = Page.new
    @page.safe_update(%w[title body tags wiki language adult_content css], params[:page])
    if (js = params[:page][:js]) && current_group.has_custom_js && current_user.role_on(current_group) == "owner"
      @page.js = js
    end
    @page.group = current_group
    @page.user = current_user

    respond_to do |format|
      if @page.save
        flash[:notice] = I18n.t("pages.create.success")
        format.html { redirect_to(@page) }
        format.json  { render :json => @page, :status => :created, :location => @page }
      else
        format.html { render :action => "new" }
        format.json  { render :json => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.json
  def update
    @page.safe_update(%w[title body tags wiki language adult_content css js], params[:page])
    @page.updated_by = current_user

    respond_to do |format|
      if @page.save
        flash[:notice] = I18n.t("pages.update.success")
        format.html { redirect_to(@page) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.json
  def destroy
    @page = current_group.pages.find(params[:id])
    @page.destroy

    respond_to do |format|
      format.html { redirect_to(pages_url) }
      format.json  { head :ok }
    end
  end

  def css
    @page = current_group.pages.by_slug(params[:id], :language => Page.current_language) || current_group.pages.by_slug(params[:id])

    if @page.has_css?
      send_data(@page.css.try(:read).to_s, :filename => "#{params[:id]}.css", :type => "text/css",  :disposition => 'inline')
    else
      render :text => ""
    end
  end

  def js
    @page = current_group.pages.by_slug(params[:id], :language => Page.current_language) || current_group.pages.by_slug(params[:id])

    if current_group.has_custom_js && @page.has_js?
      send_data(@page.js.try(:read).to_s, :filename => "#{params[:id]}.js", :type => "text/javascript",  :disposition => 'inline')
    else
      render :text => ""
    end
  end

  protected
  def check_page_permissions
    if !logged_in?
      login_required
      return false
    end

    @page = current_group.pages.by_slug(params[:id], :language => Page.current_language) || current_group.pages.by_slug(params[:id])

    if !current_user.can_edit_wiki_post_on?(current_group)
      reputation = current_group.reputation_constrains["edit_wiki_post"]

      flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                              :min_reputation => reputation,
                              :action => I18n.t("users.actions.edit_wiki_post"))
      redirect_to @page.present? ? page_path(@page) : root_path
      return false
    end
  end

  def set_layout
    if action_name == "index"
      "manage"
    else
      "application"
    end
  end
end
