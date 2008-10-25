class ArticlesController < AssetsController

protected
  def page_size
    if RAILS_ENV == "production"
      10
    else
      3
    end
  end
  
  def index_js
    # Placeholder to notify parent that js 
    # is OK to respond_to.
  end

  
end
