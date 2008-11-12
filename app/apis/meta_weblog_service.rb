require 'meta_weblog_api'
require 'base64'

class MetaWeblogService < ActionWebService::Base
  web_service_api MetaWeblogAPI

  def newPost(blog_id, user, password, struct, publish)
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate_and_set(user, password))
    raise(Hermes::NoPublicationFound, blog_id) unless publication = Publication.viewable_by(user).find_by_name(blog_id)
    raise Hermes::CannotCreateArticle unless (article = Article.add_post(user, publication, post_options(struct, publish)))
    return article.name
  end

  def editPost(post_id, user, pw, struct, publish)
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate_and_set(user, pw))
    raise Hermes::CannotUpdateArticle unless Article.update_post(user, post_id, post_options(struct, publish)) 
    return true
  end

  def getPost(post_id, user, password)
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate_and_set(user, password))
    raise Hermes::ArticleNotFound unless (post = Article.get_post(user, post_id))
    return blogify_post(post)
  end

  def getCategories(id, user, password)
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate(user, password))
    categories = []
    Category.find(:all, :order => 'name').each do |c|
      categories << Blog::Category.new(
      :description => c.name,
      :htmlUrl     => "",
      :rssUrl      => "")
    end
    categories
  end

  def getRecentPosts(blog_id, user, password, num)
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate(user, password))
    return blogify_posts(Article.published_in(Publication.current).published.viewable_by(user).recent(num))
  end
  
  def newMediaObject(blogid, user, password, struct)
    raise Hermes::UserNotAuthenticated unless (user = User.authenticate_and_set(user, password))
    raise Hermes::OnlyJpegSupported unless [".jpeg", ".jpg"].include?(File.extname(struct.name))
    filename = "#{Blog::UPLOAD_DIR}#{File.basename(struct.name)}"
    File.open(filename, File::CREAT|File::TRUNC|File::RDWR, 0644) do |f|
      f.write(struct.bits)
    end
    image = Image.import(filename)
    return image.url
  end
    
private

  def blogify_posts(articles)
    posts = []
    articles.each { |a| posts << blogify_post(a) }
    posts
  end
  
  def blogify_post(article)
    Blog::Post.new(:title => article.title, :mt_excerpt => article.description, 
      :dateCreated => article.dont_publish_before ? article.dont_publish_before.utc.iso8601 : nil,
      :postid => article.name, :mt_tags => article.tag_list.join(', '), :description => article.content, :mt_convert_breaks => article.markup_type,
      :categories => article.category_names.split(','), :mt_allow_comments => article.allow_comments, :mt_allow_pings => article.allow_pingbacks)
  end

  def post_options(struct, publish)
    {:title => struct.title, :description => struct.mt_excerpt, :content => struct.description, 
      :author => struct.author, :categories => encode_categories(struct.categories), :publishDate => struct.dateCreated, 
      :keywords => struct.mt_tags, :allow_comments => encode_allow_comments(struct.mt_allow_comments),
      :more_text => struct.mt_text_more, :allow_pingbacks => encode_allow_pings(struct.mt_allow_pings),
      :convert_breaks => struct.mt_convert_breaks, :status => encode_status(publish)
    }
  end
  
  def parse_date(datetime)
    datetime ? Time.parse(datetime).localtime : nil
  end
  
  def encode_status(publish)
    publish ? Asset::STATUS[:published] : Asset::STATUS[:draft]
  end
  
  def decode_status(status)
    status == Asset::STATUS[:published] ? true : false
  end
  
  def encode_allow_comments(allow_comments)
    # None = 0, Closed = 2, Open = 1
    return allow_comments.to_i rescue 0
  end
  
  def encode_allow_pings(allow_pings)
    # True = "1", False = "0"
    return allow_pings.to_i rescue 0
  end
  
  def encode_categories(categories)
    categories && categories.join(', ')
  end

end
