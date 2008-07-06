module Hermes
  class Error < RuntimeError; end
  class NoPublicationFound < Error; end
  class UpdateNotPermitted < Error; end
  class CreateNotPermitted < Error; end
  class DeleteNotPermitted < Error; end
  class CannotSave < Error; end
  class UserNotAuthenticated < Error; end
  class ArticleNotFound < Error; end
  class OnlyJpegSupported < Error; end
  class NoAdminUserDefined < Error; end
  class NoAnonUserDefined < Error; end
  class CannotDeleteArticle < Error; end
  class CannotCreateArticle < Error; end
  class CannotUpdateArticle < Error; end
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