module HermesSitemap
  include           ActionController::UrlWriter
  SITEMAP           = "#{RAILS_ROOT}/public/sitemap.xml"
  INCLUDE_ASSETS    = ["Article", "Image", "Gallery"]
  
  def create_sitemap(publication = nil)
    Publication.current = publication || Publication.default
    puts "Storing sitemap in #{SITEMAP}"
    f = File.new(SITEMAP, File::CREAT|File::TRUNC|File::RDWR, 0644)
    xml = Builder::XmlMarkup.new(:target => f, :indent => 2)
    xml.instruct!
    xml.urlset "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
               "xsi:schemaLocation" => "http://www.sitemaps.org/schemas/sitemap/0.9",
               :url                 => "http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd",
               :xmlns               => "http://www.sitemaps.org/schemas/sitemap/0.9" do
      assets = Asset.viewable_by(User.anonymous).published_in(Publication.current).published. \
          find(:all, :conditions => ["content_type in (?)", INCLUDE_ASSETS], :order => "content_type ASC")

      # Each asset
      assets.each do |a|
        asset = a.content
        if asset
          xml.url do
            xml.loc         polymorphic_url(asset)
            xml.lastmod     asset.updated_at.iso8601
            xml.changefreq  "weekly"
            xml.priority    "0.8"
          end
        else
          puts "Nil asset content for #{a.name} of type #{a.content_type} found - skipping."
        end
      end
    end
    f.close
  end
  
  def default_url_options
    @default_options ||= { :host => "#{Publication.current.domain}" }
  end

end