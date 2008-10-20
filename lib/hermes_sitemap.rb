module HermesSitemap
  include           ActionController::UrlWriter
  SITEMAP           = "#{RAILS_ROOT}/public/sitemap.xml"
  INCLUDE_ASSETS    = ["Article", "Image", "Gallery"]
  PRIORITY          = {"Article" => "0.8", "Image" => "0.5", "Gallery" => "0.6"}
  
  def create_sitemap(sitemap_path = SITEMAP, publication = nil)
    Publication.current = publication || Publication.default
    puts "Storing sitemap in #{sitemap_path}"
    f = File.new(sitemap_path, File::CREAT|File::TRUNC|File::RDWR, 0644)
    xml = Builder::XmlMarkup.new(:target => f, :indent => 2)
    xml.instruct!
  	
    xml.urlset "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
    	         "xsi:schemaLocation" => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd",
               :xmlns               => "http://www.sitemaps.org/schemas/sitemap/0.9",
               "xmlns:geo"          => "http://www.google.com/geo/schemas/sitemap/1.0" do
      assets = Asset.viewable_by(User.anonymous).published_in(Publication.current).published. \
          find(:all, :conditions => ["content_type in (?)", INCLUDE_ASSETS], :order => "content_type ASC")

      # Root url
      root_lastmod        = Article.last.updated_at.iso8601 rescue Time.now.iso8601
      xml.url do
        xml.loc           root_url
        xml.lastmod       root_lastmod
        xml.changefreq    "daily"
        xml.priority      "0.9"
      end

      # Each asset
      assets.each do |a|
        asset = a.content
        if asset
          xml.url do
            xml.loc         polymorphic_url(asset)
            xml.lastmod     asset.updated_at.iso8601
            xml.changefreq  "weekly"
            xml.priority    PRIORITY[a.content_type] || "0.5"
          end
          
          # All assets should allow kml generation - we need to add that to other assets first though
          if (asset.is_a?(Gallery) || asset.is_a?(Image)) && asset.mappable?
            xml.url do
              xml.loc         polymorphic_url(asset) + ".kml"
              xml.lastmod     asset.updated_at.iso8601
              xml.changefreq  "weekly"
              xml.priority    PRIORITY[a.content_type] || "0.5"              
              xml.geo :geo do
                xml.geo :format, "kml"
              end
            end
          end
        else
          puts "Nil asset content for #{a.id.to_s}:#{a.name} of type #{a.content_type} found - skipping."
        end
      end
    end
    f.close
  end
  
  def default_url_options
    @default_options ||= { :host => "#{Publication.current.domain}" }
  end

end
