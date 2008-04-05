module HermesPrintOrder
  
  class ImageSize
    attr_accessor :short, :long, :description
    
    def initialize
      @short = 0
      @long = 0
      @description = ''
    end
  end
  
  def print_sizes(options = {})
    default_options = {:type => :metric}
    options.merge(default_options)
    
    # Given the image, calculate the various print sizes
    image_sizes = []
    paper_sizes = PaperSize.find(:all, :order => "short_side_metric")
    image_short_side = self.portrait? ? self.width : self.height
    image_long_side = self.portrait? ? self.height : self.width
    image_size_ratio = image_long_side.to_f / image_short_side.to_f
    
    if options[:type] == :imperial
      measure = "in"
    else
      measure = "cm"
    end
    
    paper_sizes.each do |p|
      image_size = ImageSize.new
      if options[:type] == :imperial
        image_size.short = p.short_side_imperial
      else
        image_size.short = p.short_side_metric
      end
      image_size.long = (image_size.short * image_size_ratio).to_i
      if self.portrait?
        image_size.description = "#{image_size.short}#{measure} by #{image_size.long}#{measure}"
      else
        image_size.description = "#{image_size.long}#{measure} by #{image_size.short}#{measure}"        
      end
      image_sizes << image_size
    end
    image_sizes
  end
end
    