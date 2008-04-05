module Hermes
  class Error < RuntimeError; end
  class NoPublicationFound < Error; end
  class UpdateNotPermitted < Error; end
  class CreateNotPermitted < Error; end
  class DeleteNotPermitted < Error; end
end