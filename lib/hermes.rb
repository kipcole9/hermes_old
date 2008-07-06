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

