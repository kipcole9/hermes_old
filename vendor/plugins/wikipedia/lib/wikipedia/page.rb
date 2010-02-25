module Wikipedia
  class Page
    def initialize(json)
      require 'json'
      @data = JSON::load(json)
    end
    
    def content
      @data['query']['pages'].values.first['revisions'].first.values.first
    end
    
    def redirect?
      content.match(/\#REDIRECT\s+\[\[(.*?)\]\]/)
    end
    
    def redirect_title
      if matches = redirect?
        matches[1]
      end
    end
    
    def title
      @data['query']['pages'].values.first['title']
    end
    
    def location
      @location ||= Coordinates.new(content)
      @location.mappable? && @location.title_location? ? @location : nil
    end
    
    class Coordinates
      attr_reader :latitude, :longitude, :options
      
      # Provided in degrees, minutes and seconds
      LATLNG1 = /\{\{coord\|(\d{1,2})\|(\d{1,2})\|(\d{1,2}\.?\d{0,4})\|(N|S)\|(\d{1,3})\|(\d{1,2})\|(\d{1,2}\.?\d{0,4})\|(E|W)(.*?)\}\}/i

      # Provided in degrees and minutes
      LATLNG2 = /\{\{coord\|(\d{1,2})\|(\d{1,2})\|(N|S)\|(\d{1,3})\|(\d{1,2})\|(E|W)(.*?)\}\}/i
      
      # Provided in degrees
      LATLNG3 = /\{\{coord\|(\d{1,2}\.?\d{0,4})\|(N|S)\|(\d{1,3}\.?\d{0,4})\|(E|W)(.*?)\}\}/i            
            
      # Provided in decimal degrees
      LATLNG4 = /\{\{coord\|([-+]?\d{1,2}\.?\d{0,4})\|([-+]?\d{1,3}\.?\d{0,4})(.*?)\}\}/i
      
      LATLNG_MARKER = /\{\{coord.*?\}\}/
      
      # These are the legit parameters for a wikipedia {{coord}} template
      TEMPLATE_PARAMETERS = /\A(display|format|name)=(.*)/      
      
      def initialize(content)
        @options = {}
        if c = content.match(LATLNG1)
          @latitude   = (c[1].to_f + (c[2].to_f / 60.0) + (c[3].to_f / 3600.0)) * (c[4].match(/n/i) ? 1 : -1)
          @longitude  = (c[5].to_f + (c[6].to_f / 60.0) + (c[7].to_f / 3600.0)) * (c[8].match(/e/i) ? 1 : -1)
          params     = c[9]
        elsif c = content.match(LATLNG2)
          @latitude   = (c[1].to_f + (c[2].to_f / 60.0)) * (c[3].match(/n/i) ? 1 : -1)
          @longitude  = (c[4].to_f + (c[5].to_f / 60.0)) * (c[6].match(/e/i) ? 1 : -1)
          params     = c[7]       
        elsif c = content.match(LATLNG3)
          @latitude   = c[1].to_f * (c[2].match(/n/i) ? 1 : -1)
          @longitude  = c[3].to_f * (c[4].match(/e/i) ? 1 : -1)
          params     = c[5]
        elsif c = content.match(LATLNG4)
          @latitude   = c[1].to_f
          @longitude  = c[2].to_f
          params     = c[3]
        elsif c = content.match(LATLNG_MARKER)
          raise ArgumentError, "Couldn't parse '#{c[0]}"
        end
        
        if params
          params = params.split('|').compact.reject {|i| i.blank? } 
          make_options_from_params(@options, params)
        end
      end
      
      def mappable?
        @latitude && @longitude
      end
      
      def title_location?
        # The regexp works because the only valid options are
        # "title", "inline,title" or the shortcuts
        # "t", or "it"
        options[:display] && options[:display].match(/t/i)
      end
      
    private
      def make_options_from_params(options, params)
        params.each do |p|
          if !extract_template_options_from_param(options, p)
            extract_map_options_from_param(options, p)
          end
        end
      end
      
      def extract_template_options_from_param(options, parameter)
        if param = parameter.match(TEMPLATE_PARAMETERS)
          options[param[1].to_sym] = param[2]
        end
      end
      
      def extract_map_options_from_param(options, parameter)
        parameter.split('_').compact.each do |p|
          one_param = p.split(':')
          # Sometimes population data is included so we need to split
          # ie. 'type=city(7000000)'
          if o = one_param[1].match(/\A(.+)\((.*)\)\Z/)
            options[:population] = o[2].gsub(',','').to_i
            options[one_param[0].to_sym] = o[1]
          else
            options[one_param[0].to_sym] = one_param[1]
          end
        end
      end
    end
  end
end