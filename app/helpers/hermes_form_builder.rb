class HermesFormBuilder < ActionView::Helpers::FormBuilder

  def text_field(label, *args)
    default_options = {:size => 71, :class => "_formText"}
    if label.is_a?(String) then
      label, attribute, options = label, args[0], args[1]
      options.reverse_merge!(default_options) if options
    else
      # label is actually the method
      label, attribute, options = label.to_s, label, args[0]
      options.reverse_merge!(default_options) if options
    end

    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, options),
      {:class => "_formField"}
      )
  end
     
  def text_area(label, *args)
    default_options = {:size => "69x5", :class => "_formText"}
    if label.is_a?(String) then
      label, attribute, options = label, args[0], args[1]
    else
      # label is actually the method
      label, attribute, options = label.to_s, label, args[0]
    end
    options = default_options.merge(options)
    
    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, options),
      {:class => "_formField"}
      )    
  end

  def file_field(label, *args)
    #file_field method, options = {}
    default_options = {:size => "50", :class => "_formText"}
    if label.is_a?(String) then
      label, attribute, options = label, args[0], args[1]
    else
      # label is actually the method
      label, attribute, options = label.to_s, label, args[0]
    end
    options = default_options.merge(options)
        
    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, options),
      {:class => "_formField"}
      )    
  end
   
  def select(label, *args)
    # select("label", method, choices, options = {}, html_options = {})
    default_options = {:class => "_formText"}
    if label.is_a?(String) then
      label, attribute, choices, options, html_options = label, args[0], args[1], args[2], args[3]
    else
      # label is actually the method
      label, attribute, choices, options, html_options = label.to_s, label, args[0], args[1], args[2]
    end
    html_options = html_options ? default_options.merge(html_options) : default_options
    options = {} unless options

    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, choices, options, html_options),
      {:class => "_formField"}
      )    
  end  
   
  def check_box(label, *args)
    # method, options = {}, checked_value = "1", unchecked_value = "0"
    default_options = {:class => "_formText"}
    if label.is_a?(String) then
      label, attribute, options, checked_value, unchecked_value = label, args[0], args[1], args[2], args[3]
    else
      # label is actually the method
      label, attribute, options, checked_value, unchecked_value = label.to_s, label, args[0], args[1], args[2]
    end
    options = default_options.merge(options)
   
    @template.content_tag("div",
      @template.content_tag("label", format_label(label,:suffix => '?'), 
      :for => "#{object_name}_#{attribute}") + super(attribute, options, checked_value, unchecked_value),
      {:class => "_formField"}
      )  
  end
    
  def country_select(label, *args)
  #country_select(method, priority_countries = nil, options = {}, html_options = {})  
    default_options = {:class => "_formText"}
    if label.is_a?(String) then
      label, attribute, priority_countries, options, html_options = label, args[0], args[1], args[2], args[3]
    else
      # label is actually the method
      label, attribute, priority_countries, options, html_options = label.to_s, label, args[0], args[1], args[2]
    end
    html_options = default_options.merge(html_options)
    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, priority_countries, options, html_options),
      {:class => "_formField"}
      )
  end
  
  def datetime_select(label, *args)
    #datetime_select(object_name, method, options = {}, html_options = {})
    default_options = {:class => "_formText"}
    if label.is_a?(String) then
      label, attribute, options, html_options = label, args[0], args[1], args[2]
    else
      # label is actually the method
      label, attribute, options, html_options = label.to_s, label, args[0], args[1]
    end
    html_options = html_options ? default_options.merge(html_options) : default_options
    options = {} unless options
    
    @template.content_tag("div",
      @template.content_tag("label", format_label(label,:suffix => ':'), 
      :for => "#{object_name}_#{attribute}") + super(attribute, options, html_options),
      {:class => "_formField"}
      ) 
  end
 
  def date_select(label, *args)
    #date_select(object_name, method, options = {}, html_options = {})    
    default_options = {:class => "_formText"}
    if label.is_a?(String) then
      label, attribute, options, html_options = label, args[0], args[1], args[2]
    else
      # label is actually the method
      label, attribute, options, html_options = label.to_s, label, args[0], args[1]
    end
    html_options = default_options.merge(html_options)
    
    @template.content_tag("div",
      @template.content_tag("label", format_label(label,:suffix => ':'), 
        :for => "#{object_name}_#{attribute}") + super(attribute, options, html_options),
        {:class => "_formField"}
      ) 
  end
  
  def tz_select(label, *args)
    #time_zone_select(object, method, priority_zones = nil, options = {}, html_options = {})
    default_options = {:class => "_formText"}
    if label.is_a?(String) then
      label, attribute, priority_zones, options, html_options = label, args[0], args[1], args[2], args[3]
    else
      # label is actually the method
      label, attribute, priority_zones, options, html_options = label.to_s, label, args[0], args[1], args[2]
    end
    html_options = default_options.merge(html_options)
    
    @template.content_tag("div",
      @template.content_tag("label", format_label(label,:suffix => ':'), 
        :for => "#{object_name}_#{attribute}") +
        time_zone_select(attribute, priority_zones, options, html_options),
        {:class => "_formField"}
      ) 
  end  
    
private  
  def format_label(label, *args)
    label = label.humanize + ":"
  end
end


