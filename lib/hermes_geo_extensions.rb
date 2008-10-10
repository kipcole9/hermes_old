module HermesGeoExtensions
  DEFAULT_PUSHPIN_IMAGE     = "/images/icons/photo.png"
  DEFAULT_PUSHPIN_STYLE     = "style_image_pushpin"

  def add_document_basic_data(xml, asset, options = {})
    xml.name(options[:name] || asset.title)
    xml.description render_to_string :inline => (options[:description] || asset.description) unless options[:no_description]
    xml.atom :author do
      xml.atom :name, (options[:author] || asset.created_by.full_name)
      xml.atom :uri, root_url
    end
    xml.atom :link, :href => (options[:url] || polymorphic_url(asset))
  end    

  def add_image_placemark(xml, image, options = {})  
    if image && image.mappable?
      xml.Placemark do
        xml.name image.title
        xml.description render_to_string(:partial => "shared/image_for_google_maps.html.erb", :locals => {:image => image})
        xml.styleUrl "#" + (options[:style] || DEFAULT_PUSHPIN_STYLE)
        add_asset_extended_data(xml, image) if options[:extended_data]
        xml.Point do
          xml.coordinates "#{image.longitude},#{image.latitude},0"
        end
      end
    end
  end
  
  def add_pushpin_style(xml, options = {})
    xml.Style :id => (options[:style] || DEFAULT_PUSHPIN_STYLE) do
      xml.IconStyle do
        xml.scale "1.1"
        xml.Icon do
          xml.href root_url + (options[:pushpin_image] || DEFAULT_PUSHPIN_IMAGE)
        end
      end
    end
  end
  
  def add_asset_extended_data(xml, asset)
    xml.ExtendedData do
      ["country", "state", "city", "location", ["tag_list", "keywords"]].each do |attrib|
        attr_text = attrib.is_a?(Array) ? attrib[1] : attrib
        attr_value = attrib.is_a?(Array) ? asset.send(attrib[0]) : asset.send(attrib)
        xml.Data :name => attr_text do
          xml.value attr_value
        end if attr_value
      end
    end
  end
        
end