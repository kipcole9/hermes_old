class ArticlesController < AssetsController
  before_filter   :retrieve_assets, :only => [:index]

  def retrieve_assets
    @articles = Article.published_in(publication).published.viewable_by(current_user) \
        .conditions(marshall_params).order('assets.created_at DESC') \
        .with_category(params[:category]) \
        .pager(unescape(params[:tags]), params[:page])  
    if @articles.blank?
      flash[:notice] = "Requested articles not found!"
      redirect_back_or_default('/')
    end
  end
  
  # This is really a helper - but for some reason render_to_string can't be found in a helper,
  # nor is it found in a builder template
  def render_description(article)
    description = article.description.sub(/<%= *image/,"<%= image_rss")
    description = description.sub(/<%= *thumb/,"<%= image_rss")
    description = description.sub(/<%= *gallery/,"<%= gallery_rss")
    render_to_string :inline => description
  end
  
end
