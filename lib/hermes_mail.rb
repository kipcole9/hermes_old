require 'pp'
require 'net/pop'
#require 'action_mailer'

class HermesMail
  TMP_DIR       = "#{RAILS_ROOT}/tmp"
  attr_accessor :mail_host, :mail_port, :mail_user, :mail_password
  
  def initialize(options = {})
    @mail_host = options[:host]
    @mail_port = options[:port] || 110
    @mail_user = options[:user]
    @mail_password = options[:password]
  end
  
  def self.test(options= {})
    handler = self.new(options)
    handler.get_mail do |m|
      puts "From: #{m.from}"
      puts "Subject: #{m.subject}"
      m.body.each do |s, v|
        puts "Body type #{s}"
        v.each_with_index do |vv, i|
          puts "#{i}:  #{vv}"
        end
      end
      m.images.each do |i|
        puts "Image file #{i}"
      end
    end
  end
  
  def get_mail(options = {}, &block)
    raise Hermes::HostParameterRequired unless @mail_host
    Net::POP3.start(@mail_host, @mail_port, @mail_user, @mail_password) do |pop|
      if pop.mails.empty?
        RAILS_DEFAULT_LOGGER.info 'HermesMail: No mail.'
      else
        pop.each_mail do |m|   # or "pop.mails.each ..."
          yield IncomingMailHandler.receive(m.pop)
          m.delete if options[:delete] == true
        end
        RAILS_DEFAULT_LOGGER.info "HermesMail: #{pop.mails.size} mails popped."
        pop.mails.size
      end
    end
  end

  class IncomingMailHandler < ActionMailer::Base
    # email is a TMail::Mail
    def receive(email)
      message = Message.new
      message.from = email.from
      message.subject = email.subject
      process_email(email, message)
      return message
    end
    
    def process_email(email, message)
      #email.attachments are TMail::Attachment
      #but they ignore a text/mail parts.
      if email.multipart?
        idx = 1
        email.parts.each do |part|
          if part.multipart?
            process_email(part, message)
          else
            process_part(part, idx, message)
            idx += 1
          end
        end
      else
        message.from = email.from
        message.subject = email.subject
        message.body[ext(email)] = [] unless email.body[ext(email)]
        message.body[ext(email)].push email.body
      end
    end

    def process_part(part, idx, message)
      filename = part_filename(part)
      filename = "#{idx}.#{ext(part)}" if filename.nil?
      RAILS_DEFAULT_LOGGER.debug "----#{idx}-#{filename}----" 
      filepath = TMP_DIR + '/' + filename
      case ext(part)
      when "jpg"
        File.open(filepath, "wb") do |f|
          f.write( part.body )
        end
        message.images.push filepath
      when "html", "plain"
        # Hash of types; arrayed in order
        message.body[ext(part).to_sym] = [] unless message.body[ext(part).to_sym]
        message.body[ext(part).to_sym].push part.body
      end
    end

    def part_filename(part)

      # print some useful informaion
      #puts "...." 
      RAILS_DEFAULT_LOGGER.debug  "transfer_encoding: #{part.transfer_encoding}" 
      RAILS_DEFAULT_LOGGER.debug  "content loca: #{part['content-location']}" 
      RAILS_DEFAULT_LOGGER.debug  "content type: #{part.content_type}" 
      RAILS_DEFAULT_LOGGER.debug  "   main type: #{part.main_type}" 
      RAILS_DEFAULT_LOGGER.debug  "    sub type: #{part.sub_type}" 
      RAILS_DEFAULT_LOGGER.debug  "  type param:" 
      RAILS_DEFAULT_LOGGER.debug  "     charset: #{part.type_param('charset')}" 
      RAILS_DEFAULT_LOGGER.debug  "        name: #{part.type_param('name')}" 
      RAILS_DEFAULT_LOGGER.debug  "disposition type : #{part.disposition}" 
      RAILS_DEFAULT_LOGGER.debug  "   param-filename: #{part.disposition_param('filename')}" 
      RAILS_DEFAULT_LOGGER.debug  "...." 

      # get filename
      if part['content-location'] && part['content-location'].body.length > 0
        filename = part['content-location'].body
      elsif part.type_param('name')  && part.type_param('name').length > 0
        filename = part.type_param('name')
      elsif part.disposition_param('filename') && part.disposition_param('filename').length > 0
        filename = part.disposition_param('filename')
      else
        filename = nil
      end
      filename
    end

    CTYPE_TO_EXT = {
      'image/jpeg' => 'jpg',
      'image/gif'  => 'gif',
      'image/png'  => 'png',
      'image/tiff' => 'tif',
      'text/plain' => 'plain',
      'text/html'  => 'html'
    }

    def ext( mail )
      CTYPE_TO_EXT[mail.content_type] || 'txt'
    end      
  end
  
  class Message
    TAGS = /<tags>(.*)<\/tags>/i
    CATEGORY = /<category>(.*)<\/category>/i
    
    attr_accessor :from, :subject, :body, :images, :options
    
    def initialize
      self.body = {}
      self.images = []
      self.options = {}
    end
    
    def extract_options
      self.options[:description] = self.body[:plain] ? self.body[:plain].join(" ").gsub("\n",' ').gsub("\r",' ').strip : nil
      if self.options[:description]
        if tags = options[:description].match(TAGS)
          self.options[:tags] = tags[1].strip
          self.options[:description] = self.options[:description].sub(TAGS, '')
        end
        
        if category = self.options[:description].match(CATEGORY)
          self.options[:category] = category[1].strip
          self.options[:description] = self.options[:description].sub(CATEGORY, '')
        end
      end
      self.options[:description] = options[:description].gsub(/ +/, " ") if options[:description]
      self.options[:title] = self.subject
      self.options[:folder] = "email"
      self.options
    end
        
  end
end
