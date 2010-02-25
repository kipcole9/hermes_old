class ContentRating < ActiveRecord::Base

  DEFAULT = find_by_default_rating(true).rating
  
  def self.default
    return DEFAULT
  end
  
  def self.select_array
    find(:all, :select => "name, rating").collect!{|c| [c.name, c.rating] }
  end

end
