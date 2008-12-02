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
    render :inline => excerpt
  end
  
  # Article rendering needs to consider the markup involved
  # which is either "simple", "textile", "none"
  # By default we also do the smartypants thing to transform typographic symbols
  # RedCloth appears to do a smartypants all on its own
  def render_content(article)
    case article.markup_type
    when "simple"
      rendered_text = render_to_string(:inline => simple_format(article.full_content))
      markup = RubyPants.new(rendered_text).to_html
    when "textile"
      rendered_text = render_to_string(:inline => article.full_content)
      markup = RedCloth.new(rendered_text).to_html
    else
      rendered_text = render_to_string(:inline => article.full_content)
      markup = RubyPants.new(rendered_text).to_html
    end
    markup
  end
  
end