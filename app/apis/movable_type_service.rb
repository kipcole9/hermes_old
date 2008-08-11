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
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate_and_set(user, password))
    raise(Hermes::ArticleNotFound, "Post '#{postid}' was not found.") unless (article = Article.get_post(user, postid))    
    categories = categorise(structs)
    article.category_names = categories
    raise(Hermes::CannotSave, formatted_errors(article)) unless article.save
    true
  end
  
  def publishPost
  end
  
  def getTrackbackPings
  end
  
  def getRecentPostTitles
    titlise(Article.recent(User.default_user, num))
  end
  
  def getPostCategories(postid, user, password)
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate_and_set(user, password))
    raise(Hermes::ArticleNotFound, "Post '#{postid}' was not found.") unless (article = Article.get_post(user, postid))
    post_categories = []    
    article.category_names.split(',').each do |t|
      post_categories << Blog::PostCategory.new(:categoryName => t.strip, :categoryId => t.strip, :isPrimary => false)
    end
    return post_categories
  end
  
  def getCategoryList(blogid, user, password)
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate(user, password))
    categories = []
    Category.find(:all, :order => 'name ASC').each do |c|
      categories << Blog::MtCategory.new(:categoryId => c.name, :categoryName => c.name)
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
    categories.join(', ')
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
  
  def formatted_errors(a)
    a.errors.full_messages.join(' / ')
  end  
end
