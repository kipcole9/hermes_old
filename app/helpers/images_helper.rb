module ImagesHelper
  
  # Turn the shot data (XMP) into tag searches on images
  def image_tag_link(link_data)
    if link_data[:item].is_a?(Array)
      link_data[:item].map {|i| link_to(h(i[1]), images_url(i[0].to_sym => h(i[1])))}.join(", ")
    else
      if link_data[:param]
        if link_data[:param].is_a?(Array)
          link_to(h(link_data[:item]), images_url(link_data[:param][0].to_sym => h(link_data[:param][1])))
        else
          link_to(h(link_data[:item]), images_url(link_data[:param].to_sym => h(link_data[:item])))
        end
      else
        link_data[:item]
      end
    end
  end
  
end