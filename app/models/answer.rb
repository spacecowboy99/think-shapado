class Answer < Comment
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include Support::Versionable
  key :_id, String

  key :body, String, :required => true
  key :language, String, :default => "en"
  key :votes_count, Integer, :default => 0
  key :votes_average, Integer, :default => 0
  key :flags_count, Integer, :default => 0
  key :banned, Boolean, :default => false
  key :wiki, Boolean, :default => false

  timestamps!

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  key :question_id, String
  belongs_to :question

  has_many :votes, :as => "voteable", :dependent => :destroy
  has_many :flags, :as => "flaggeable", :dependent => :destroy

  has_many :comments, :foreign_key => "commentable_id", :class_name => "Comment", :order => "created_at asc", :dependent => :destroy

  validates_presence_of :user_id
  validates_presence_of :question_id

  versionable_keys :body
  filterable_keys :body

  validate :disallow_spam
  validate :check_unique_answer, :if => lambda { |a| !a.group.forum }

  def check_unique_answer
    check_answer = Answer.first(:question_id => self.question_id,
                               :user_id => self.user_id)

    if !check_answer.nil? && check_answer.id != self.id
      self.errors.add(:limitation, "Your can only post one answer by question.")
      return false
    end
  end

  def add_vote!(v, voter)
    self.collection.update({:_id => self._id}, {:$inc => {:votes_count => 1,
                                                          :votes_average => v}},
                                                         :upsert => true)

    if v > 0
      self.user.update_reputation(:answer_receives_up_vote, self.group)
      voter.on_activity(:vote_up_answer, self.group)
      self.user.upvote!(self.group)
    else
      self.user.update_reputation(:answer_receives_down_vote, self.group)
      voter.on_activity(:vote_down_answer, self.group)
      self.user.downvote!(self.group)
    end
  end

  def remove_vote!(v, voter)
    self.collection.update({:_id => self._id}, {:$inc => {:votes_count => -1,
                                                          :votes_average => (-v)}},
                                                         :upsert => true)

    if v > 0
      self.user.update_reputation(:answer_undo_up_vote, self.group)
      voter.on_activity(:undo_vote_up_answer, self.group)
      self.user.upvote!(self.group, -1)
    else
      self.user.update_reputation(:answer_undo_down_vote, self.group)
      voter.on_activity(:undo_vote_down_answer, self.group)
      self.user.downvote!(self.group, -1)
    end
  end

  def flagged!
    self.collection.update({:_id => self._id}, {:$inc => {:flags_count => 1}},
                                               :upsert => true)
  end


  def ban
    self.question.answer_removed!
    self.collection.update({:_id => self._id}, {:$set => {:banned => true}},
                                               :upsert => true)
  end

  def self.ban(ids)
    self.find_each(:_id.in => ids, :select => [:question_id]) do |answer|
      answer.ban
    end
  end

  def to_html
    Maruku.new(self.body).to_html
  end

  def disallow_spam
    eq_answer = Answer.first({:body => self.body,
                                :question_id => self.question_id,
                                :group_id => self.group_id
                              })

    last_answer  = Answer.first(:user_id => self.user_id,
                                 :question_id => self.question_id,
                                 :group_id => self.group_id,
                                 :order => "created_at desc")

    valid = (eq_answer.nil? || eq_answer.id == self.id) &&
            ((last_answer.nil?) || (Time.now - last_answer.created_at) > 20)
    if !valid
      self.errors.add(:body, "Your answer looks like spam.")
    end
  end

  protected

end
