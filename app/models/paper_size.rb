class PaperSize < ActiveRecord::Base
  CONVERT_IN_TO_CM    = 2.54
  CONVERT_CM_TO_IN    = 1 / CONVERT_IN_TO_CM
  
  def short_side_metric=(value)
    write_attribute(:short_side_metric, value)
    write_attribute(:short_side_imperial, value * CONVERT_CM_TO_IN )
  end
  
  def short_side_imperial=(value)
    write_attribute(:short_side_imperial, value)
    write_attribute(:short_side_metric, value * CONVERT_IN_TO_CM )
  end    
  
end