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
          alias_method :ar_to_xml, :to_xml
          
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
          
          def self.all_polymorph_readers
            readers = [polymorph_class.polymorph_readers, polymorph_class.polymorph_accessors, polymorph_class.content_columns.map(&:name)].flatten
            readers.reject! {|r| r == "id"}
            readers
          end

          def self.all_polymorph_writers
            writers = [polymorph_class.polymorph_writers, polymorph_class.polymorph_accessors, polymorph_class.content_columns.map(&:name)].flatten
            writers.reject! {|r| r == "id"}
            writers
          end           
          
          def initialize(attrs = nil)
            super(nil)
            self.#{polymorph_name} = #{polymorph_class_name}.new
            self.attributes = attrs
            self
          end

          define_delegate_readers
          define_delegate_writers
          define_meta_methods
          include InstanceMethods
        END_EVAL
      end
      
      # Attribute methods that proxy the Asset class attributes so we can mass assign
      # and otherwise update as if they were in this class
      def define_delegate_readers
        # Create delegate methods for polymorphic attributes/methods
        all_polymorph_readers.each do |attr|
          class_eval <<-END_EVAL
            def #{attr.to_s}
              return polymorph.#{attr.to_s}
            end
          END_EVAL
        end
      end
        
      def define_delegate_writers  
        # and writers
        all_polymorph_writers.each do |attr|
          class_eval <<-END_EVAL
            def #{attr.to_s}= (val)
              polymorph.#{attr.to_s} = val
            end
          END_EVAL
        end
      end
      
      # Instance methods to find the polymorph
      def define_meta_methods
        class_eval <<-END_EVAL
          def polymorph
            self.#{polymorph_name}
          end
                         
          def #{polymorph_name}_id
            polymorph.id
          end
        END_EVAL
      end
    end

    module InstanceMethods
      def save(f = true)
        # Save on a new record will also automatically save the Asset record
        acts_as_polymorph_class.transaction do
          is_new = self.new_record?
          if result = super
            result = polymorph.save(f) unless is_new
          end
          polymorph.errors.each {|e, m| self.errors.add(e, m)}
          raise BadPolymorphicSave unless result # Raise forces rollback
          true
        end
      rescue BadPolymorphicSave
        false
      end
      
      def destroy
        acts_as_polymorph_class.transaction do
          raise BadPolymorphicDestroy unless super
        end
        true
      rescue BadPolymorphicDestroy
        false
      end
    
      def to_xml(options = {})
        default_except = [:crypted_password, :salt, :remember_token, 
                          :remember_token_expires_at, :created_at, :updated_at]
        polymorph_attrs = polymorph_class.polymorph_xml_attrs                  
                          
        # Need to watch out - when called on an array element, options are acculumated.
        # Thankfully options are not validated so we can use one to ensure we don't double up.                  
        unless options[:first_loop_done] == 'yes'
          options[:except] = (options[:except] ? options[:except] + default_except : default_except)
          options[:methods] = (options[:methods] ? options[:methods] + polymorph_attrs : polymorph_attrs)
          options[:first_loop_done] = 'yes'
        end
        ar_to_xml(options)
      end     
    end
  end
end
