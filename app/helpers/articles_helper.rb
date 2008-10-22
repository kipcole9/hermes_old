module ArticlesHelper
  
  def render_excerpt(article)
    if article.content
      if article.description.match(/<\/p>\Z/)
        excerpt = article.description.sub(/<\/p>\Z/, link_to(" More&hellip;", article) + "</p>" )
      else
        excerpt = article.description + " " + link_to("More&hellip;", article)
      end
    else
      excerpt = article.description
    end
    render_to_string :inline => excerpt
  end
  
end