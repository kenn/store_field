require 'store_field/version'
require 'store_field/railtie'
require 'active_record'

module StoreField
  extend ActiveSupport::Concern

  module ClassMethods
    def store_field(key, options = {})
      raise ArgumentError.new(':in is invalid')     if options[:in] and serialized_attributes[options[:in].to_s].nil?
      raise ArgumentError.new(':type is invalid')   if options[:type] and ![ Hash, Set ].include?(options[:type])
      raise ArgumentError.new(':values is invalid') if options[:values] and !options[:values].is_a?(Array)

      klass = options[:type]
      values = options[:values]
      store_attribute = options[:in] || serialized_attributes.keys.first
      raise ArgumentError.new('store method must be defined before store_field') if store_attribute.nil?

      # Accessor
      define_method(key) do
        value = send(store_attribute)[key]
        if value.nil?
          value = klass ? klass.new : {}
          send(store_attribute)[key] = value
        end
        value
      end

      # Utility methods for Set
      if options[:type] == Set
        define_method("set_#{key}") do |value|
          raise ArgumentError.new("#{value.inspect} is not allowed") if values and !values.include?(value)
          send(key).add(value)
          self
        end
        define_method("unset_#{key}")   {|value| send(key).delete(value); self }
        define_method("set_#{key}?")    {|value| send(key).include?(value) }
        define_method("unset_#{key}?")  {|value| !send(key).include?(value) }
      end
    end
  end
end
