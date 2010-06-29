class GroupNetwork
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Storage
  include MongoMapperExt::Filter

  timestamps!

  key :group_ids, Array #and 
  
  has_many :groups, :in => :group_ids

  def group_ids
    TagList.first(:group_id => self.id) || TagList.create(:group_id => self.id)
  end


end
