define Topic do
  belongs_to :site, stub_site
  belongs_to :section
  has_many   :comments
  has_one    :last_comment, stub_comment
  
  methods    :sticky? => false,
             :locked? => false,
             :save => true,
             :destroy => true,
             :revise => true,
             :last_page => 2,
             :last_comment => stub_comment,
             :last_updated_at => Time.now(),
             :last_author_name => 'last_author_name'
             
  instance   :topic,
             :id => 1,
             :title => 'a topic',
             :permalink => 'a-topic'

end

scenario :topic do
  scenario :comment
  @topic = stub_topic
end

scenario :two_topics do
  scenario :user, :site
  
  @forum = Forum.new
  @forum.stub!(:id).and_return 1
  @forum.stub!(:new_record?).and_return false
  @forum.stub!(:site).and_return stub_site
  
  attributes = {:title => 'title', :body => 'body', :last_author => stub_user, :section => @forum}
  @earlier_topic = Topic.create! attributes.update(:last_updated_at => 1.month.ago)
  @latest_topic = Topic.create! attributes.update(:last_updated_at => Time.now)
  
  @earlier_topic.stub!(:section).and_return @forum
  @latest_topic.stub!(:section).and_return @forum
end