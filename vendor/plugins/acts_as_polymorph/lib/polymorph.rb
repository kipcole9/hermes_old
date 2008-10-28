module Hermes
  module Polymorph #:nodoc:
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      class BadPolymorphicSave < RuntimeError; end
      class BadPolymorphicDestroy < RuntimeError; end
      
      # For the "master" class
      def acts_as_polymorph_asset(options = {})
        configuration = { :accessors => [], :readers => [], :writers => [], :to_xml => [] }
        configuration.update(options) if options.is_a?(Hash)
        class_eval <<-END_EVAL
          @@polymorph_accessors = configuration[:accessors]
          @@polymorph_readers   = configuration[:readers]
          @@polymorph_writers   = configuration[:writers]
          @@polymorph_xml_attrs = configuration[:to_xml]
        END_EVAL
        cattr_reader  :polymorph_accessors, :polymorph_readers, :polymorph_writers, :polymorph_xml_attrs
      end
      
      # For the "child" classes
      def acts_as_polymorph(options = {})
        configuration = { :name => :asset, :as => :content }
        configuration.update(options) if options.is_a?(Hash)
        
        polymorph_name        = configuration[:name].to_s.downcase
        polymorph_class_name  = polymorph_name.capitalize
        polymorph_table_name  = ActiveSupport::Inflector.pluralize(polymorph_name)
        my_table_name         = ActiveSupport::Inflector.pluralize(base_class.name).downcase
        as_name               = configuration[:as].to_s.downcase
        
        class_eval <<-END_EVAL
          has_one :#{polymorph_name}, :as => :#{as_name}, :dependent => :destroy
          
          def acts_as_polymorph_class
            ::#{self.name}
          end
          
          def self.polymorph_class
            #{polymorph_class_name}
          end
          
          def self.polymorph_table_name
            "#{polymorph_table_name}"
          end
          
          def self.polymorph_class_name
            "#{polymorph_class_name}"
          end
          
          def self.polymorph_name
            "#{polymorph_name}"
          end
          
          def initialize(attrs = nil)
            super(nil)
            self.#{polymorph_name} = #{polymorph_class_name}.new
            self.attributes = attrs
            self
          end

          define_delegate_methods(#{polymorph_class_name})
          define_instance_methods(#{polymorph_class_name})
        END_EVAL
      end
      
      # Attribute methods that proxy the Asset class attributes so we can mass assign
      # and otherwise update as if they were in this class
      def define_delegate_methods(polymorph_class_name)
        polymorph_name = polymorph_class_name.to_s.downcase
        
        # Create delegate methods for polymorphic attributes/methods
        # that are defined in the asset class
        [polymorph_class_name.polymorph_readers, polymorph_class_name.polymorph_accessors, polymorph_class_name.content_columns.map(&:name)].flatten.each do |attr|
          class_eval <<-END_EVAL
            def #{attr.to_s}
              return self.#{polymorph_name}.#{attr.to_s}
            end
          END_EVAL
        end
        
        # and writers
        [polymorph_class_name.polymorph_writers, polymorph_class_name.polymorph_accessors, polymorph_class_name.content_columns.map(&:name)].flatten.each do |attr|
          class_eval <<-END_EVAL
            def #{attr.to_s}= (val)
              self.#{polymorph_name}.#{attr.to_s} = val
            end
          END_EVAL
        end
        
        # define to_xml; including attributes defined for the #{polymorph_name}
        class_eval <<-END_EVAL
          alias_method :ar_to_xml, :to_xml
          def to_xml(options = {})
            default_except = [:crypted_password, :salt, :remember_token, 
                              :remember_token_expires_at, :created_at, :updated_at]
            polymorph_attrs = #{polymorph_class_name}.polymorph_xml_attrs                  
                              
            # Need to watch out - when called on an array element, options are acculumated.
            # Thankfully options are not validated so we can use one to ensure we don't double up.                  
            unless options[:first_loop_done] == 'yes'
              options[:except] = (options[:except] ? options[:except] + default_except : default_except)
              options[:methods] = (options[:methods] ? options[:methods] + polymorph_attrs : polymorph_attrs)
              options[:first_loop_done] = 'yes'
            end
            ar_to_xml(options)
          end
        END_EVAL
      end
      
      # Instance methods to synchronise saving between the two classes
      def define_instance_methods(polymorph_class_name)
        polymorph_name = polymorph_class_name.to_s.downcase
        class_eval <<-END_EVAL          
          def save(f = true)
            # Save on a new record will also automatically save the Asset record
            acts_as_polymorph_class.transaction do
              is_new = self.new_record?
              if result = super
                result = self.#{polymorph_name}.save(f) unless is_new
              end
              self.#{polymorph_name}.errors.each {|e, m| self.errors.add(e, m)}
              raise BadPolymorphicSave unless result # Raise forces rollback
              true
            end
          rescue BadPolymorphicSave
            false
          end
          
          def save!
            save || raise(RecordNotSaved)
          end
          
          def destroy
            acts_as_polymorph_class.transaction do
              raise BadPolymorphicDestroy unless super
            end
            true
          rescue BadPolymorphicDestroy
            false
          end

          def #{polymorph_name}_id
            self.#{polymorph_name}.id
          end
          
          def find_by_name_or_id(param)
            return nil unless param 
            if (param.is_a?(String) && param.is_integer?) || param.is_a?(Fixnum)
              find(:first, :conditions => ["#{table_name}.id = ?", param], :include => polymorph_name.to_sym)
            else
              find_by_name(param)
            end
          end
          
          def find_by_name(param)
            return nil unless param 
            find(:first, :conditions => ["#{polymorph_table_name}.name = ?",param], :include => polymorph_name.to_sym)
          end
          
          def page(num, per_page =  10)
            find(:all, :page => {:size => per_page, :current => num})
          end          
                      
        END_EVAL
      end
    end

    module InstanceMethods

    end
  end
end
