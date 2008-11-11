class ArticlesController < AssetsController

protected
  def page_size
    respond_to do |format|
      format.html { return 10  }
      format.any  { return 100 }
    end
  end
  
  def index_js

  end

  
end
