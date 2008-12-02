class ArticlesController < AssetsController

protected
  def page_size
    respond_to do |format|
      format.html { return 10  }
      format.js   { return 10  }      
      format.any  { return 100 }
    end
  end
  
  def index_js
    # Done only to force the correct mime type.  Rails 2.2.0 will set the wrong mime type
    # whereas rails 2.2.0 set the correct mime type.
    render :template => "articles/index.js.rjs", :content_type => "text/javascript"
  end

  
end
