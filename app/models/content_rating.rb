class ContentRating < ActiveRecord::Base

  DEFAULT = find_by_default_rating(true).rating
  
  def self.default
    return DEFAULT
  end

end
