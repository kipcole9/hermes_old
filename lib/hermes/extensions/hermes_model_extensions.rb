module Hermes
  module ModelExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    include ActionController::UrlWriter

    # For pingbacks
    def add_pingback(sourceURI, body)
      Comment.add_pingback(self, sourceURI, body)
    end

    # Announce articles to Defensio spam analyser?
    def self.defensio?
      true
    end
      
    def author_name
      self.created_by.full_name
    end

    def author_email
      self.asset.created_by_email
    end

    def create_date
      self.asset.created_at.strftime("%Y/%m/%d")
    end
  
    def to_param
      self.name
    end
      
    def permalink
      send("#{self.class.name.downcase}_url", self, :host => Publication.current.domain)
    end

    module ClassMethods    
      def default_url_options
        { :host => Publication.current.domain }
      end
    end
  end
end