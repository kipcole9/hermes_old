class ArticlesController < AssetsController
  before_filter   :retrieve_assets, :only => [:index]

  def retrieve_assets
    @articles = Article.published_in(publication).published.viewable_by(current_user) \
        .included_in_index(current_user) \
        .conditions(marshall_params).order('assets.created_at DESC') \
        .with_category(params[:category]) \
        .pager(unescape(params[:tags]), params[:page])  
  end
  
end
