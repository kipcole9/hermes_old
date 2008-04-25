class HermesFormBuilder < ActionView::Helpers::FormBuilder

  def text_field(label, *args)
    default_options = {:size => 71, :class => "_formText"}
    attribute, new_options = set_options(label, args, default_options)

    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, new_options),
      {:class => "_formField"}
      )
  end
     
  def text_area(label, *args)
    default_options = {:size => "69x5", :class => "_formText"}
    attribute, new_options = set_options(label, args, default_options)
    
    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, new_options),
      {:class => "_formField"}
      )    
  end

  def file_field(label, *args)
    default_options = {:size => "50", :class => "_formText"}
    attribute, new_options = set_options(label, args, default_options)
    
    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, new_options),
      {:class => "_formField"}
      )    
  end
   
  def select(label, *args)
    default_options = {:class => "_formText"}
    if args.first.is_a?(Symbol) || args.first.is_a?(String) then
      choices = args[1]
      args.delete_at(1)
    else
      choices = args[0]
      args.delete_at(0)
    end

    attribute, new_options = set_options(label, args, default_options)
    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, choices, new_options),
      {:class => "_formField"}
      )    
  end  
   
  def check_box(label, *args)
    default_options = {:class => "_formText"}
    attribute, new_options = set_options(label, args, default_options)    
    @template.content_tag("div",
      @template.content_tag("label", format_label(label,:suffix => '?'), 
      :for => "#{object_name}_#{attribute}") + super(attribute, new_options),
      {:class => "_formField"}
      )  
  end
    
  def country_select(label, *args)
    default_options = {:class => "_formText"}
    if args.first.is_a?(Symbol) || args.first.is_a?(String) then
      choices = args[1]
      args.delete_at(1)
    else
      choices = args[0]
      args.delete_at(0)
    end

    attribute, new_options = set_options(label, args, default_options)
    @template.content_tag("div",
      @template.content_tag("label", format_label(label), 
      :for => "#{object_name}_#{attribute}") + super(attribute, choices, new_options),
      {:class => "_formField"}
      )
  end
  
  def datetime_select(label, *args)
    default_options = {:class => "_formText"}
    attribute, new_options = set_options(label, args, default_options)
    
    @template.content_tag("div",
      @template.content_tag("label", format_label(label,:suffix => ':'), 
      :for => "#{object_name}_#{attribute}") + super(attribute, new_options),
      {:class => "_formField"}
      ) 
  end
 
  def date_select(label, *args)
    default_options = {:class => "_formText"}
    attribute, new_options = set_options(label, args, default_options)
    @template.content_tag("div",
      @template.content_tag("label", format_label(label,:suffix => ':'), 
        :for => "#{object_name}_#{attribute}") + super(attribute, new_options),
        {:class => "_formField"}
      ) 
  end
  
  def tz_select(label, *args)
    # expects object, attribute firs....
    default_options = {:class => "_formText"}
    attribute, new_options = set_options(label, args, default_options)
    @template.content_tag("div",
      @template.content_tag("label", format_label(label,:suffix => ':'), 
        :for => "#{object_name}_#{attribute}") +
        time_zone_select(attribute.to_sym),
        {:class => "_formField"}
      ) 
  end  
    
private  
  def set_options(label, args, defaults) 
    attribute = args.first.is_a?(Symbol) || args.first.is_a?(String) ? args.first.to_s : label
    options = args.last.is_a?(Hash) ? args.pop : {}
    new_options = defaults.merge(options)   
    return attribute, new_options 
  end
   
  def format_label(label, *args)
    defaults = {:suffix => ":"}
    options = args.last.is_a?(Hash) ? args.pop : {}
    options = defaults.merge(options)
    
    label = label.to_s
    label = label.last != options[:suffix] ? label += options[:suffix] : label
    label = label.humanize
  end
end


