module HermesModelExtensions

  # Used in to_xml for Assets and Asset polymorphs
  def asset_xml(asset, xml)
    xml.title(asset.title)
    xml.description(asset.description)
    xml.tag_list(asset.tag_list)
    xml.sublocation(asset.sublocation)
    xml.location(asset.location)
    xml.city(asset.city)
    xml.state(asset.state)
    xml.country(asset.country)
    xml.content_rating(asset.content_rating)
    xml.latitude(asset.latitude)
    xml.longitude(asset.longitude)
    xml.altitude(asset.altitude)
  end

end
