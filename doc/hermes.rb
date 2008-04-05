# Returns the column object for the named attribute.
module Hermes
  module ActiveRecord
    module Extensions
      #KIP COLE - VERY CRUDE PATCH TO SUPPORT POLYMORPHIC ASSIGNMENT
      def column_for_attribute(name)
        if !(col = self.class.columns_hash[name.to_s])
          if self.class.respond_to?(:polymorph_class) and name.to_s != "updated_at" and name.to_s != "created_at"
            col = self.class.polymorph_class.columns_hash[name.to_s] 
          end
        end
        col
      end
    end
  end
end
ActiveRecord::Base.send(:extend, Hermes::ActiveRecord::Extensions)





