class Article < ActiveRecord::Base
  include ActionController::UrlWriter
  acts_as_polymorph
  acts_as_secure
  has_many :pages

  def leader
    self.asset.description
  end
  
  def leader=(val)
    self.asset.description = val
  end
  
  def full_content
    self.content.blank? ? self.description : self.description + ' ' + self.content
  end
  
  #
  # For Defensio spam protections service attribute methods
  #
  def author_name
    self.asset.created_by.full_name
  end
  
  def author_email
    self.asset.created_by.email
  end
  
  def permalink
    publications_url(self.name)
  end
  
  def create_date
    self.created_at.strftime("%Y/%m/%d")
  end
  
  #
  #  Methods supporting the MovableType and Metaweblog xmlrpc interfaces
  #
  def self.add_post(user, publication, options = {})
    raise Hermes::CreateNotPermitted unless Article.can_create?(user)
    raise Hermes::NoPublicationFound unless publication
    article = self.new
    article.set_options(options)
    article.publications |= publication.bit_id
    article.created_by = user
    raise(Hermes::CannotSave, formatted_errors(article)) unless article.save
    return article
  end
  
  def self.update_post(user, article_id, options = {})
    return nil unless (article = self.get_post(user, article_id))
    raise Hermes::UpdateNotPermitted unless article.can_update?(user)
    article.set_options(options)
    raise(Hermes::CannotSave, formatted_errors(article)) unless article.save
    return article
  end

  def self.get_post(user, article_id)
    viewable_by(user).find_by_name(article_id)
  end
  
  def self.delete_post(user, article_id)
    return nil unless (article = viewable_by(user).find_by_name(article_id))
    raise Hermes::DeleteNotPermitted unless article.can_delete?(user)
    article.status = Asset::STATUS["deleted"]
    raise(Hermes::CannotSave, formatted_errors(article)) unless article.save
    return true
  end

  def set_options(options)
    self.title = options[:title] unless options[:title].blank?
    self.category_names = options[:categories] unless options[:categories].blank?
    self.content = options[:content] unless options[:content].blank?
    self.description = options[:description] unless options[:descrition].blank?
    self.tag_list = options[:keywords] unless options[:keywords].blank?
    self.dont_publish_before = options[:publishDate] unless options[:publishDate].blank?
    self.status = options[:status] unless options[:status].blank?
    self.allow_comments = options[:allow_comments]
    self.markup_type = options[:convert_breaks]
  end
  
private
  def formatted_errors(a)
    a.errors.full_messages.join(' / ')
  end  

end