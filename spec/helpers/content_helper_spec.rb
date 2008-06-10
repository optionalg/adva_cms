require File.dirname(__FILE__) + '/../spec_helper'

describe ContentHelper do
  include Stubby
  
  before :each do
    scenario :article
  end
  
  describe '#published_at_formatted' do
    it "returns 'not published' if the article is not published" do
      @article.stub!(:published?).and_return false
      helper.published_at_formatted(@article).should == 'not published'
    end
    
    it "returns a short formatted date if the article was published in the current year" do
      @article.stub!(:published_at).and_return Time.local(Time.now.year, 1, 1)
      helper.published_at_formatted(@article).should == 'January 1st'
    end
    
    it "returns a mdy formatted date if the article was published before the current year" do
      @article.stub!(:published_at).and_return Time.local(Time.now.year - 1, 1, 1)
      helper.published_at_formatted(@article).should =~ /January 1st, [\d]+/
    end
  end
  
  describe '#content_path' do
    it "returns an article_path if the given content's section is a Blog" do
      scenario :blog
      @article.stub!(:section).and_return @blog
      helper.should_receive(:article_path)
      helper.content_path(@article)
    end
    
    it "returns a wikipage_path if the given content's section is a Wiki" do
      scenario :wikipage
      helper.should_receive(:wikipage_path)
      helper.content_path(@wikipage)
    end
    
    it "returns a section_article_path if the given content's section is a Section" do
      scenario :section
      @article.stub!(:section).and_return @section
      helper.should_receive(:section_article_path)
      helper.content_path(@article)
    end
  end
  
  describe '#content_url' do
    before :each do
      helper.stub!(:content_path).and_return '/path/to/content'
      helper.stub!(:request).and_return ActionController::TestRequest.new
    end
    
    it "delegates to content_path" do
      helper.should_receive(:content_path).and_return '/path/to/content'
      helper.content_url @article
    end

    it "prepends the current protocol, host and port" do
      helper.content_url(@article).should == 'http://test.host/path/to/content'
    end    
  end
  
  describe '#link_to_content_comments_count' do
    before :each do
      @article.stub!(:comments_count).and_return 3
      @article.stub!(:approved_comments_count).and_return 2
      helper.stub!(:content_path).and_return '/path/to/content'
    end
    
    it "returns a link_to_content_comments" do      
      helper.link_to_content_comments_count(@article).should have_tag('a[href=?]', '/path/to/content')
    end  
    
    it "given the option :total is set it returns a link_to_content_comments with the approved and total comments counts as a link text" do
      helper.link_to_content_comments_count(@article, :total => true).should =~ /\d{2} \(\d{2}\)/
    end
    
    it "given the option :total is not set it returns a link_to_content_comments with the total comments count as a link text" do
      helper.link_to_content_comments_count(@article).should =~ /\d{2}/
    end
    
    it "given the content has no comments it returns the option :alt as plain text" do
      @article.stub!(:approved_comments_count).and_return 0
      helper.link_to_content_comments_count(@article, :alt => 'no comments').should == 'no comments'
    end
    
    it "given the content has no comments and no option :alt was passed it returns 'none' as plain text" do
      @article.stub!(:approved_comments_count).and_return 0
      helper.link_to_content_comments_count(@article).should == 'none'
    end
  end
  
  describe '#link_to_content_comments' do
    before :each do
      scenario :comment
      @article.stub!(:comments_count).and_return 3
      @article.stub!(:approved_comments_count).and_return 2
      helper.stub!(:content_path).and_return '/path/to/content'
    end
    
    it "given a content it returns a link to content_path" do
      helper.link_to_content_comments(@article).should have_tag('a[href=?]', '/path/to/content')
    end
    
    # TODO wtf ... why does this break? it looks as if content_path would never have been stubbed
    # it "given a content and a comment it returns a link to content_path + comment anchor" do
    #   helper.should_receive(:content_path).with @article, :anchor => 'comment_1'
    #   helper.link_to_content_comments(@article, @comment)
    # end
    
    it "given the first arg is a String it uses the String as link text" do
      helper.link_to_content_comments('link text', @article).should =~ /link text/
    end
    
    it "given the first arg is not a String it uses 'x comments' as link text" do
      helper.link_to_content_comments('link text', @article).should =~ /link text/
    end
    
    it "given the content has no approved comments and the content does not accept comments it returns nil" do
      @article.stub!(:approved_comments_count).and_return 0
      @article.stub!(:accept_comments?).and_return false
      helper.link_to_content_comments(@article).should be_nil
    end
  end
  
  describe "#link_to_content_comment" do
    before :each do
      scenario :comment
    end
    
    it "being a shortcut, inserts the comment's commentable to the args and calls link_to_content_comments" do
      @comment.should_receive(:commentable).and_return(@article)
      helper.should_receive(:link_to_content_comments).with(@article, @comment)
      helper.link_to_content_comment(@comment)
    end
  end
  
  describe "#link_to_category" do
    before :each do
      scenario :section, :category
      helper.stub!(:section_category_path).and_return '/path/to/section/category'
    end
    
    it "links to the given category" do
      helper.link_to_category(@category).should have_tag('a[href=?]', '/path/to/section/category')
    end
    
    it "given the first argument is a String it uses the String as link text" do
      helper.link_to_category('link text', @category).should =~ /link text/
    end
    
    it "given the first argument is not a String it uses the category title as link text" do
      @category.stub!(:title).and_return 'category title'
      helper.link_to_category(@category).should =~ /category title/
    end
  end
  
  describe "#links_to_content_categories" do
    before :each do
      scenario :section, :category
      helper.stub!(:link_to_category).and_return 'link_to_category'
    end
    
    it "returns nil if the content has no categories" do
      @article.stub!(:categories).and_return []
      helper.links_to_content_categories(@article).should be_nil
    end
    
    it "returns an array of links to the given content's categories" do
      helper.links_to_content_categories(@article).should == ['link_to_category', 'link_to_category']
    end
    
    it "given a format_string as second argument it joins the links with a comman and interpolates them to the format_string" do
      helper.links_to_content_categories(@article, '<b>%s</b>').should == '<b>link_to_category, link_to_category</b>'
    end
  end
  
  describe "#link_to_tag" do
    before :each do
      scenario :section, :tag
      helper.stub!(:section_tag_path).and_return '/path/to/section/tags/tag-1'
    end
    
    it "links to the given tag" do
      helper.link_to_tag(@section, @tag).should have_tag('a[href=?]', '/path/to/section/tags/tag-1')
    end
    
    it "given the first argument is a String it uses the String as link text" do
      helper.link_to_tag('link text', @section, @tag).should =~ /link text/
    end
    
    it "given the first argument is not a String it uses the tag name as link text" do
      @tag.stub!(:name).and_return 'tag-1'
      helper.link_to_tag(@section, @tag).should =~ /tag-1/
    end
  end
  
  describe '#links_to_content_tags' do
    before :each do
      scenario :section, :tag
      helper.stub!(:link_to_tag).and_return 'link_to_tag'
    end
    
    it "returns nil if the content has no tags" do
      @article.stub!(:tags).and_return []
      helper.links_to_content_tags(@article).should be_nil
    end
    
    it "returns an array of links to the given content's tags" do
      helper.links_to_content_tags(@article).should == ['link_to_tag', 'link_to_tag']
    end
    
    it "given a format_string as second argument it joins the links with a comman and interpolates them to the format_string" do
      helper.links_to_content_tags(@article, '<b>%s</b>').should == '<b>link_to_tag, link_to_tag</b>'
    end
  end
  
  describe "#content_category_checkbox" do
    before :each do
      scenario :category
    end
    
    it "given an Article it names the checkbox 'article[category_ids][]'" do
      helper.content_category_checkbox(@article, @category).should have_tag('input[type=?][name=?]', 'checkbox', 'article[category_ids][]')
    end
    
    it "given an Article and a Category with the id 1 it gives the checkbox the id 'article_category_1'" do
      helper.content_category_checkbox(@article, @category).should have_tag('input[type=?][id=?]', 'checkbox', 'article_category_1')
    end
    
    it "given an Article that belongs to the given Category the checkbox is checked" do
      helper.content_category_checkbox(@article, @category).should have_tag('input[type=?][checked=?]', 'checkbox', 'checked')
    end
    
    it "given an Article that does not belong to the given Category it the checkbox is not checked" do
      @article.stub!(:categories).and_return []
      helper.content_category_checkbox(@article, @category).should_not =~ /checked/
    end
  end
  
  
end