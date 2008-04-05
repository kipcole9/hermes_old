class IndexController < AssetsController

  def retrieve_assets
    @articles = Article.published_in(publication).published.viewable_by(current_user).find(:all, :order => 'created_at DESC', :limit => 10)
  end
  
end