require 'movable_type_api'

class MovableTypeService < ActionWebService::Base
  web_service_api MovableTypeAPI

  def supportedTextFilters
    [Blog::Filter.new(:key => "filter 1", :label => "label 1")]
  end
  
  def supportedMethods
    []
  end
  
  def setPostCategories(postid, user, password, structs)
    raise "Not authorised" if !(user = User.authenticate(user, password))
    if article = Article.get_post(user, postid)
      tag_list = categorise(structs)
      category_ids = Category.find(:all, :conditions => ["name in (?)", tag_list]).map(&:id)
      article.category_ids = category_ids
      article.save!
      true
    else
      raise "Post '#{postid}' was not found."
    end
  end
  
  def publishPost
  end
  
  def getTrackbackPings
  end
  
  def getRecentPostTitles
    titlise(Article.recent(User.default_user, num))
  end
  
  def getPostCategories(postid, user, password)
    raise "Not authorised" if !(user = User.authenticate(user, password))
    post_categories = []
    if article = Article.get_post(user, postid)
      article.categories.each do |t|
        post_categories << Blog::PostCategory.new(:categoryName => t.name, :categoryId => t.id, :isPrimary => false)
      end
      return post_categories
    else
      raise "Post '#{postid}' was not found."
    end
  end
  
  def getCategoryList(blogid, user, password)
    raise "Not authorised" if !(user = User.authenticate(user, password))
    categories = []
    Category.find(:all, :order => 'name ASC').each do |c|
      categories << Blog::MtCategory.new(:categoryId => c.id, :categoryName => c.name)
    end
    categories
  end
  
private
  def titlise(articles)
    titles = []
    articles.each do |a|
      titles << Blog::Title.new(:dateCreated => a.created_at.strftime(Blog::ISO8601),
        :userid => a.created_by.full_name, :postid => a.name, :title => a.title)
    end
    titles
  end
    
  def categorise(structs)
    categories = []
    structs.each {|s| categories << s.categoryName }
    categories
  end
  
  def unique(a1, a2)
    lcase = []
    dest = []
    aa = a1 + a2
    aa.each do |a|
      unless lcase.include?(a.downcase)
        dest << a
        lcase << a.downcase
      end
    end
    dest
  end
end
