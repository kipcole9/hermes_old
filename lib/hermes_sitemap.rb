module HermesSitemap
  include           ActionController::UrlWriter
  require           'cgi'
  require           'rest_client'
  HTML_SITEMAP      = "/sitemap.xml"
  GEO_SITEMAP       = "/geo_sitemap.xml"
  INCLUDE_ASSETS    = ["Article", "Image", "Gallery"]
  PRIORITY          = {"Article" => "0.8", "Image" => "0.5", "Gallery" => "0.6"}
  ENGINES =  {:google => "http://www.google.com/webmasters/tools/ping?sitemap=",
              :yahoo =>"http://search.yahooapis.com/SiteExplorerService/V1/updateNotification?appid=YJSNbUrV34ED_e4h67aKpPCduy5mZfijO1zjIG1IAn2BNt0mDMiLOsv_3laYS6_kEw--&url=",
              :msn => "http://webmaster.live.com/ping.aspx?siteMap="}  
  
  def create_sitemap(sitemap_path = SITEMAP, publication = nil)
    create_html_sitemap(sitemap_path = "#{RAILS_ROOT}/public/#{HTML_SITEMAP}", publication = nil)
    create_geo_sitemap(sitemap_path = "#{RAILS_ROOT}/public/#{GEO_SITEMAP}", publication = nil)
    ping_search_engines([HTML_SITEMAP, GEO_SITEMAP])
  end
  
  def test_ping
    ping_search_engines([HTML_SITEMAP, GEO_SITEMAP])
  end  
  
  def create_html_sitemap(sitemap_path = SITEMAP, publication = nil)
    Publication.current = publication || Publication.default
    puts "Storing html sitemap in #{sitemap_path}"
    f = File.new(sitemap_path, File::CREAT|File::TRUNC|File::RDWR, 0644)
    xml = Builder::XmlMarkup.new(:target => f, :indent => 2)
    xml.instruct!
  	
    xml.urlset "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
    	         "xsi:schemaLocation" => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd",
               :xmlns               => "http://www.sitemaps.org/schemas/sitemap/0.9" do
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
        else
          puts "Nil asset content for #{a.id.to_s}:#{a.name} of type #{a.content_type} found - skipping."
        end
      end
    end
    f.close
  end
  
  def create_geo_sitemap(sitemap_path = SITEMAP, publication = nil)
    Publication.current = publication || Publication.default
    puts "Storing geo sitemap in #{sitemap_path}"
    f = File.new(sitemap_path, File::CREAT|File::TRUNC|File::RDWR, 0644)
    xml = Builder::XmlMarkup.new(:target => f, :indent => 2)
    xml.instruct!
  	
    xml.urlset "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
    	         "xsi:schemaLocation" => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd",
               :xmlns               => "http://www.sitemaps.org/schemas/sitemap/0.9",
               "xmlns:geo"          => "http://www.google.com/geo/schemas/sitemap/1.0" do
      assets = Asset.viewable_by(User.anonymous).published_in(Publication.current).published. \
          find(:all, :conditions => ["content_type in (?) AND latitude IS NOT NULL AND longitude IS NOT NULL", INCLUDE_ASSETS], :order => "content_type ASC")

      # Root url
      root_lastmod        = Article.last.updated_at.iso8601 rescue Time.now.iso8601
      # Each asset
      assets.each do |a|
        asset = a.content
        if asset
          # All assets should allow kml generation - we need to add that to other assets first though
          if (asset.is_a?(Gallery) || asset.is_a?(Image))
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
  
  def ping_search_engines(sitemaps)
    sitemaps.each do |sitemap|
      ENGINES.each do |provider, provider_url|
        url = provider_url + CGI.escape(root_url + sitemap)
        begin
          #puts "Pinging #{url}"
          #result = RestClient.get(url)
          puts "Pinged #{provider.to_s.capitalize} for sitemap '#{sitemap}'."
        rescue RestClient::RequestFailed => e
          puts "Error pinging #{provider.to_s.capitalize} for sitemap '#{sitemap}'. Code #{e.http_code}"
          puts result if result
        end
      end
    end     
  end  
  
  def default_url_options
    @default_options ||= { :host => "#{Publication.current.domain}" }
  end

end
