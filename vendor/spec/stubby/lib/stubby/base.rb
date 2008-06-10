# class Object
#   alias :treequal_without_stubby :===
#   def self.===(object)
#     if object.respond_to? :stubby?
#       return object.class == self
#     end
#     super
#   end
# end

module Stubby
  class Base        
    class << self
      attr_accessor :original_class
      
      def stubby?
        true
      end
      
      def new
        returning super do |object|
          object.instance_variable_set :@original_class, original_class
        end  
      end
      
      def base_class
        original_class.base_class
      end
    end
    
    def to_param
      id.to_s
    end
    
    def class
      @original_class
    end
    
    def new_record?
      id.nil?
    end

    def is_a?(klass)
      @original_class.ancestors.include? klass
    end
    alias :kind_of? :is_a?
  
    def instance_of?(klass)
      @original_class == klass
    end
      
    def stubby?
      true
    end
  end
end