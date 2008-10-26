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

  end

  
end
