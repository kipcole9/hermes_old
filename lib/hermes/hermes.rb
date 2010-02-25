module Hermes
  class Error < RuntimeError; end
  class UserNotAuthenticated < Error; end
  class NoCurrentUser < Error; end
  
  class PingError < Error; end
  class BadPingUri < PingError; end
  class PingbackError < PingError; end
    
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
  
  class HostParameterRequired < Error; end
  
  def default_url_options
    {:host => Publication.current.domain}
  end
  

end
