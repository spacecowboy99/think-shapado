class FeedbackWidget < Widget
  before_validation_on_create :set_name

  def local_version
    @local_version = AppConfig.version
  end

  protected
  def set_name
    self[:name] ||= "feedback"
  end
end
