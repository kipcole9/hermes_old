class ArticlesController < AssetsController

protected
  def page_size
    respond_to do |format|
      format.html { 10  }
      format.any  { 100 }
    end
  end
  
  def index_js

  end

  
end
