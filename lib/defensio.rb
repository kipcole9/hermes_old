class Defensio
  require 'net/http'
  require 'uri'
  require 'cgi'
  
  class Error < RuntimeError; end
  class MandatoryParameterMissing < Error; end
  class InvalidAPIKey < Error; end
  class NoSignatures < Error; end
  class InvalidRequest < Error; end
  class NoArticle < Error; end
  class NoComment < Error; end

  attr_accessor    :response
  CONFIG           = YAML::load_file("#{RAILS_ROOT}/config/defensio.yml")["#{RAILS_ENV}"].symbolize_keys
  SERVER           = "http://api.defensio.com/blog"

  # Api description for Defensio service
  API  = {
    :validate_key     => {:action => "validate-key", :owner_url => :mandatory},
    :announce_article => {:action => "announce-article", :owner_url => :mandatory, :article_author => :mandatory,
                          :article_author_email => :mandatory, :article_title => :mandatory, :article_content => :mandatory,
                          :permalink => :mandatory},
    :audit_comment    => {:action => "audit-comment", :owner_url => :mandatory, :user_ip => :mandatory,
                          :article_date => :mandatory, :comment_author => :mandatory, :comment_type => :mandatory,
                          :comment_content => :optional, :comment_author_email => :optional, :test_force => :optional,
                          :comment_author_url => :optional, :permalink => :optional, :referrer => :optional, 
                          :user_logged_in => :optional, :trusted_user => :optional, :openid => :optional},
    :report_false_negative => {:action => "report-false-negatives", :signatures => :mandatory, :owner_url => :mandatory},
    :report_false_positive => {:action => "report-false-positives", :signatures => :mandatory, :owner_url => :mandatory},
    :get_stats             => {:action => "get-stats", :owner_url => :mandatory}
  }
  
  # Method mappings to resolve Article and Comment attributes for Defensio service
  METHOD_MAP = {
    :article => {
      :article_author       => "author_name",
      :article_author_email => "author_email",
      :article_title        => "title",
      :article_content      => "full_content",
      :permalink            => "permalink",
      :article_date         => "create_date"
    },

    :default => {
      :article_author       => "author_name",
      :article_author_email => "author_email",
      :article_title        => "title",
      :article_content      => "description",
      :permalink            => "permalink",
      :article_date         => "create_date"      
    },
  
    :comment => {
      :user_ip              => "user_ip",
      :comment_author       => "author_name",
      :comment_type         => "source",
      :comment_content      => "content",
      :comment_author_email => "author_email",
      :comment_author_url   => "author_url",
      :signatures           => "signature"
    }
  }
  
  def initialize(options = {})
    options.each {|k, v| CONFIG[k] = v }
    CONFIG[:api_version] ||= "1.2"
    CONFIG[:server]      ||=  SERVER
    CONFIG[:debug]       ||=  true
    if RAILS_ENV == "production"
      CONFIG[:api_key]     = Publication.current.defensio_api_key if Publication.current and Publication.current.defensio_api_key
    end
    if !validate_key
      raise(InvalidAPIKey, "API Key '#{CONFIG[:api_key]}' is invalid") 
    end unless CONFIG[:no_validate_key]
    true
  end
  
  def validate_key(options = {})
    merged_options = CONFIG.merge(options)
    @response = post(API[:validate_key], merged_options)
    success?(@response)
  end
  
  def announce_article(article, options = {})
    raise NoArticle if article.nil?
    merged_options = CONFIG.merge(extract_options(article)).merge(options)
    @response = post(API[:announce_article], merged_options)
    success?(@response)  
  end
  
  def audit_comment(article, comment, options = {})
    raise NoArticle if article.nil?
    raise NoComment if comment.nil?
    options[:referrer] ||= User.environment['HTTP_REFERER'] if defined?(User) && User.respond_to?("environment") && User.environment['HTTP_REFERER']
    options[:user_logged_in] ||= User.logged_in? ? "true" : "false" if defined?(User) && User.respond_to?("logged_in?")
    options[:trusted_user] ||= User.current_user.is_admin? ? "true" : "false" if defined?(User)
    merged_options = CONFIG.merge(extract_options(article)).merge(extract_options(comment)).merge(options)
    @response = post(API[:audit_comment], merged_options)
    success?(@response)    
  end
  
  def report_false_negative(comment, options = {})
    raise NoComment if comment.nil?
    merged_options = CONFIG.merge(extract_options(comment)).merge(options)
    @response = post(API[:report_false_negative], merged_options)
    success?(@response)
  end
  
  def report_false_positive(comment, options = {})
    raise NoComment if comment.nil?
    merged_options = CONFIG.merge(extract_options(comment)).merge(options)
    @response = post(API[:report_false_positive], merged_options)
    success?(@response)
  end
  
  def get_stats(options = {})
    merged_options = CONFIG.merge(options)
    @response = post(API[:get_stats], merged_options)
    success?(@response)
  end
    
private    
  def extract_options(obj)
    options = {}
    method_map = METHOD_MAP[obj.class.name.downcase.to_sym] || METHOD_MAP[:default]
    method_map.each do |k, v|
      options[k] = obj.send(v)
    end
    options
  end

  def server_url(action, options)  
    "#{options[:server]}/#{options[:api_version]}/#{action}/#{options[:api_key]}.yaml"
  end
  
  def convert_name(name)
    name.to_s.tr('_', '-')
  end
  
  def post_encode(post_data)
    params = {}
    post_data.each {|k, v| params[convert_name(k)] = CGI.escape(v.to_s) }
    params
  end
  
  def create_request(api, options)
    request = {}
    api.each do |k, v|
      raise(MandatoryParameterMissing, "Option '#{k}' is required for action #{api[:action]}") if v == :mandatory && options[k].blank?
      request[convert_name(k)] = options[k] unless k == :action || options[k].blank? 
    end
    request
  end
  
  def post(api, options)
    request = create_request(api, options)
    RAILS_DEFAULT_LOGGER.debug "Defensio request: #{server_url(api[:action], options)}"
    response = Net::HTTP.post_form(URI.parse(server_url(api[:action], options)), request)
    if response.class == Net::HTTPOK
      result =  YAML::load(response.body)["defensio-result"]
      RAILS_DEFAULT_LOGGER.debug "Defensio result: #{result.inspect}"
      return result
    else
      RAILS_DEFAULT_LOGGER.debug "Error: Received:\n================\n#{response.body}\n================" if response.body
      raise InvalidRequest, response.inspect
    end
  end
  
  def success?(response)
    response["status"] == "success"
  end
  
end
