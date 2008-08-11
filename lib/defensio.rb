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
                          :comment_content => :optional, :comment_author_email => :optional, 
                          :comment_author_url => :optional, :permalink => :optional},
    :report_false_negative => {:action => "report-false-negative", :signatures => :mandatory},
    :report_false_positive => {:action => "report-false-positive", :signatures => :mandatory},
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
  
    :comment => {
      :user_ip              => "user_ip",
      :comment_author       => "author_name",
      :comment_type         => "source",
      :comment_content      => "content",
      :comment_author_email => "author_email",
      :comment_author_url   => "author_url"
    }
  }
  
  def initialize(options = {})
    options.each {|k, v| CONFIG[k] = v }
    CONFIG[:api_version] ||= "1.2"
    CONFIG[:server]      ||=  SERVER
    if !validate_key
      raise(InvalidAPIKey, "API Key '#{CONFIG[:api_key]}' is invalid") 
    end unless CONFIG[:no_validate_key]
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
    merged_options = CONFIG.merge(extract_options(article)).merge(extract_options(comment)).merge(options)
    @response = post(API[:audit_comment], merged_options)
    success?(@response)    
  end
  
  def report_false_negative(signatures, options = {})
    signature_string = signatures.is_a?(Array) ? signatures.join(',') : signatures
    raise NoSignatures, "No signatures were supplied" if signature_string.blank?
    merged_options = CONFIG.merge(options).merge({:signatures => signature_string})
    @response = post(API[:report_false_negative], merged_options)
    success?(@response)
  end
  
  def report_false_positive(signatures, options = {})
    signature_string = signatures.is_a?(Array) ? signatures.join(',') : signatures
    raise NoSignatures, "No signatures were supplied" if signature_string.blank?
    merged_options = CONFIG.merge(options).merge({:signatures => signature_string})
    @response = post(API[:report_false_postive], merged_options)  
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
    METHOD_MAP[obj.class.name.downcase.to_sym].each do |k, v|
      options[k] = obj.send(v) rescue nil
    end
    options
  end

  def server_url(action, options)  
    "#{options[:server]}/#{options[:api_version]}/#{action}/#{options[:api_key]}.yml"
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
    puts "Sending #{server_url(api[:action], options)}"
    unless options[:debug]
      response = Net::HTTP.post_form(URI.parse(server_url(api[:action], options)), request)
      if response.class == Net::HTTPOK
        return YAML::load(response.body)["defensio-result"]
      else
        raise InvalidRequest, response.inspect
      end
    else
      puts "Defensio(debug only): Action: #{api[:action]}"
      puts "                      Server: #{server_url(api[:action], options)}"
      puts request.inspect
      {"status" => "success"}
    end
  end
  
  def success?(response)
    response["status"] == "success"
  end
  
end
