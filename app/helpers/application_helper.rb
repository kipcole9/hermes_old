# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include HermesHelper
  
  def stylesheet_link_theme
    if publication.theme && File.exist?("#{RAILS_ROOT}/public/stylesheets/#{publication.theme}.css")
      if request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"].match("MSIE")
  		  stylesheet_link_merged("#{publication.theme}_ie".to_sym)
		  else
		    stylesheet_link_merged(publication.theme.to_sym)
	    end
  	else
  		stylesheet_link_merged :base
  	end
	end

  def serve_image_link(image, options = {})
    image_name = image.is_a?(Image) ? image.name : image
    image_filename = "#{image_name}-#{options[:type].to_s}" if options[:type]
    image_link = image_filename || image_name
    formatted_image_url(image_link, :jpg)
  end
  
  def link_to_image(image_name, options = {})
    return options[:text] unless image = Image.viewable_by(current_user).find_by_name_or_filename(image_name)
    link_text = options[:text] || image.title
    link_to link_text, image_url(image)
  end
  
  def link_to_gallery(gallery_name, options = {})
    return options[:text] unless gallery = Gallery.viewable_by(current_user).find_by_name_or_id(gallery_name)
    link_text = options[:text] || gallery.title
    link_to link_text, gallery_url(gallery)
  end
      
  def link_to_kml(kml_file_name, link_text)
    link_to link_text, "/kml/#{kml_file_name}.kml"
  end
  
  def link_to_google_map(kml_file_name, link_text)
    link_to link_text, "http://maps.google.com?q=" + CGI.escape("http://www.noexpectations.com.au/kml/#{kml_file_name}.kml")
  end
    
  def render_description(asset)
    return "" unless asset.description
    description = asset.description.sub(/<%= *image/,"<%= image_rss")
    description = description.sub(/<%= *thumb/,"<%= image_rss")
    description = description.sub(/<%= *gallery/,"<%= gallery_rss")
    render_to_string :inline => description
  end
  
  def format_content(content)
    auto_link(sanitize(content))
  end
  
  def bookmark(name, options = {})
    if b = Bookmark.viewable_by(current_user).find_by_name(name)
      u = b.url
      t = options[:text].blank? ? b.title : options[:text]
    else
      u = '#'
      t = "{Bookmark '#{name}' not found}"
    end
    link_to t, u
  end
  
  def image(name, options = {})
    if i = Image.viewable_by(current_user).published.published_in(publication).find_by_name_or_filename(name)
      if options[:size] && options[:size] == :large
        render :partial => "images/display.html.erb", :locals => {:image => i}
      else
        render :partial => "images/thumbnail.html.erb", :locals => {:image => i}
      end
    else
      "{image '#{name}' not found}"
    end
  end
  
  def image_rss(name, options = {})
    if i = Image.viewable_by(current_user).published.published_in(publication).find_by_name(name)
      render :partial => "images/thumbnail_rss.html.erb", :locals => {:image => i}
    else
      "{image '#{name}' not found}"
    end
  end  

  def gallery(name)
    if g = Gallery.viewable_by(current_user).published.published_in(publication).find_by_name(name)
      render :partial => "images/thumbnail.html.erb", :locals => {:image => g.popular_image(current_user)}
    else
      "{gallery '#{name}' not found}"
    end
  end
  
  def sanitize_params(params)
    params.remove("controller").remove("action").remove("format")
  end
  
  def publication
    controller.publication
  end
    
  def page_title
    controller.page_title
  end
  
  def formatted_index_heading
    controller.formatted_index_heading
  end
  
  def edit_url(asset)
    send("edit_#{asset.class.name.downcase}_path", asset)
  end
  
  def show_url(asset)
    send("#{asset.class.name.downcase}_path", asset)    
  end
  
  def get_method
    case params[:action]
  	when "new", "create" 	# go to create action
  		method = :post
  	when "edit", "update"	# go to update action
  		method = :put
  	else		# otherwise show
  		method = :get
  	end
	end
	
	def geocode_message(asset)
	  case asset.geocode_method
  		when Asset::GEO_GOOGLE 
  			msg = "Geocoded by Google; #{Google_geocode_accuracy[asset.geocode_accuracy]} accuracy."
  	  when Asset::GEO_GPS
  	    msg = "Geocoded by GPS; accuracy within 3m."
  		when Asset::GEO_MANUAL 
  			msg = "Geocoded manually; accuracy within 10m."
  		else
  			msg = ""
  	end
  	msg
	end
	
  def base_uri
    # This is only used in a form_for, so we can discard any supplied parameters (there shouldn't be any anyway)
    unless @base_uri
      @base_uri = request.request_uri.split("?")[0].split('/')
      @base_uri = @base_uri[0..-2].join('/')
    end
    @base_uri
  end

  def get_url(obj)
    case params[:action]
  	when "new", "create" 	# go to create action
  	  url = base_uri
		when "edit"
		  url = base_uri # + "/#{params[:id]}"
  	else		# otherwise show
  	  url = base_uri + "/show"
  	end
  	url
	end

  def is_show?
    params[:action] == "show" ? true : false
  end
  
  def back_link(url = "/")
    session[:return_to] || url
  end


  # Help to create tag clouds.  You pass in an array of Tags and 
  # an array of css classes. It will yield to your block for each
  # tag
  def tag_cloud(tags, classes)
    max, min = 0, 1000
    tags.each { |t|
    max = t.count.to_i if t.count.to_i > max
    min = t.count.to_i if t.count.to_i < min
    }

    divisor = ((max - min) / classes.size) + 1

    tags.each { |t|
      yield t.name, classes[(t.count.to_i - min) / divisor]
    }
  end
  
  def tag_link(taglist, url_helper)
    links = []
    taglist.each {|t| links.push( "<a href=\"#{send(url_helper.to_s, :tags => h(t))}\">#{t}</a>") }
    link_list = links.join(", ")
    link_list
  end
  
  def format_pagination_links(pagingEnum, options)
      link_to_current_page = options[:link_to_current_page]
      always_show_anchors = options[:always_show_anchors]
      padding = options[:window_size]

      current_page = pagingEnum.page
      html = ''

      #Calculate the window start and end pages 
      padding = padding < 0 ? 0 : padding
      first = pagingEnum.page_exists?(current_page  - padding) ? current_page - padding : 1
      last = pagingEnum.page_exists?(current_page + padding) ? current_page + padding : pagingEnum.last_page

      # Print start page if anchors are enabled
      html << yield(1) if always_show_anchors and not first == 1

      # Print window pages
      first.upto(last) do |page|
        (current_page == page && !link_to_current_page) ? html << page : html << yield(page)
      end

      # Print end page if anchors are enabled
      html << yield(pagingEnum.last_page) if always_show_anchors and not last == pagingEnum.last_page
      html
    end
end
