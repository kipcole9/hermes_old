module HermesHelper
  def hermes_form_for(name, *args, &block)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options = options.merge!(:builder => HermesFormBuilder)   
    args = args << options 
    form_for(name, *args, &block)
  end
end


