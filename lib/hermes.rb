module Hermes
  class Error < RuntimeError; end
  class UserNotAuthenticated < Error; end
  class NoCurrentUser < Error; end
  class PingbackError < Error; end
    
  class NotFound < Error; end
  class NoPublicationFound < NotFound; end
  class ArticleNotFound < NotFound; end
  
  class TitleNotSet < Error; end
    
  class UpdateNotPermitted < Error; end
  class CreateNotPermitted < Error; end
  class DeleteNotPermitted < Error; end
  class CannotDeleteArticle < DeleteNotPermitted; end
  class CannotCreateArticle < CreateNotPermitted; end
  class CannotUpdateArticle < UpdateNotPermitted; end  
  
  class CannotSave < Error; end

  class OnlyJpegSupported < Error; end
  class NoAdminUserDefined < Error; end
  class NoAnonUserDefined < Error; end
  
  class BadPolymorphicSave < Error; end
  
  def default_url_options
    {:host => Publication.current.domain}
  end
  

end

# Returns the column object for the named attribute.
module ActiveRecord
  class Base
    #KIP COLE - VERY CRUDE PATCH TO SUPPORT POLYMORPHIC MASS ASSIGNMENT OF MULTI-PART ATTRIBUTES (datetime etc)
    public
    def column_for_attribute(name)
      if !(col = self.class.columns_hash[name.to_s])
        if self.class.respond_to?(:polymorph_class) && name.to_s != "updated_at" && name.to_s != "created_at"
          col = self.class.polymorph_class.columns_hash[name.to_s] 
        end
      end
      col
    end
  end
end