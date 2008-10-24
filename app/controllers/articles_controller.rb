class ArticlesController < AssetsController

protected
  def page_size
    3
  end
  
  def index_js
    # Placeholder to notify parent that js 
    # is OK to respond_to.
  end

  
end
