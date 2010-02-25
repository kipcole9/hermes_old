module Hermes
  module ControllerExtensions
    require 'cgi'

    def page_title(title = nil)
      unless title
        case params[:action]
        when "index"
          category = params[:category] ? "#{params[:category].capitalize} " : ""
          args = display_params ? " #{display_params}" : ""
          tags = params[:tags] ? " (tagged with #{params[:tags]})" : ""
          heading = "#{publication.title} - #{formatted_index_heading}"
        when "show"
          heading = "#{publication.title} #{class_name}"
        else
          heading = "#{publication.title} - #{params[:action].capitalize} #{class_name}"
        end
        heading << (!@asset.blank? ? " - " + @asset.title : '')
        # heading << " with criteria '#{format_query_params}'" if format_query_params
        heading
      else
        "#{publication.title}: " + title
      end
    end
  
    def formatted_index_heading
      unless @formatted_index_heading
        category = params[:category] ? "#{params[:category].capitalize} " : ""
        args = display_params ? " #{display_params}" : ""
        tags = params[:tags] ? " (tagged with '#{params[:tags]}')" : ""
        @formatted_index_heading = "#{category}#{class_name.pluralize}#{args}#{tags}"
      end
      @formatted_index_heading
    end

    # Displays ActiveRecord error messages as first sidebar
    def set_error_sidebar(obj = nil)
      @error_object = obj || @object
      if @error_object.errors.count > 0
        sidebar :show_error_messages , :layout => "sidebars/sidebars_error_layout"
        sidebar_move :show_error_messages, :top
      end
    end
    
    def format_query_params
      Asset.send("sanitize_sql", marshall_params)
    end

    def asset_obj(klass = nil)
      Object.const_get(klass || class_name)
    end

    def class_name
      @class_name ||= self.class.name.sub(/Controller/,'').singularize
    end
  
    def instance_variable_singular
      @ivar_s ||= "@#{class_name.downcase}"
    end

    def instance_variable_plural
      @ivar_p ||= "@#{class_name.downcase.pluralize}"
    end
  
    def view_path
      view_class = class_name.downcase.pluralize
      "#{RAILS_ROOT}/app/views/#{view_class}/#{params[:action]}.html.erb"
    end
  
    def param_name
      asset_obj.name.downcase.to_sym
    end
  
    # Transform parameters into SQL conditions.  Apply only for parameters that 
    # are columns in either the base table or the asset table.
    def marshall_params
      unless @marshall_params
        sql_text = []
        sql_params = []
        sql_params[0] = nil
        params.each do |k, v|
          if column = is_column?(k)
            sql_text << "#{column} = ?"
            sql_params << v
          end
        end
        sql_params[0] = sql_text.join(" AND ") if sql_text.length > 0
        @marshal_params = sql_params[0] ? sql_params : nil
      end
      @marshal_params
    end
  
    def display_params
      unless @display_params
        sql_text = []
        params.each do |k, v|
          if is_column?(k)
            sql_text << "#{k.humanize} is '#{v}'"
          end
        end
        sql_params = " where " + sql_text.join(" and ") if sql_text.length > 0
        @display_params = sql_params || nil
      end
      @display_params
    end
  
    def is_column?(column)
      return "#{asset_obj.table_name}.#{column}" if asset_obj.columns.map(&:name).include?(column)
      if asset_obj.respond_to?("polymorph_class")
        return "#{asset_obj.polymorph_class.table_name}.#{column}" \
            if asset_obj.polymorph_class.columns.map(&:name).include?(column)
      end
      false
    end
    
    def unescape(param)
      if param
        CGI.unescapeHTML(param)
      else
        nil
      end
    end

    def retrieve_asset_from_path(uri, user, publication)
      paths = [] && URI.parse(uri).path.sub(/\A\//,"").split('/')
      controller_name, asset_name = paths[0], paths[1]
      raise(BadPingUri, uri) unless controller_name && asset_name && paths.length == 2
      asset = asset_obj(controller_name.singularize.capitalize)
      asset.viewable_by(user).published.published_in(publication).find_by_name(asset_name)
    rescue NameError
      raise(BadPingURI, "No such asset class")  
    end
  end
end