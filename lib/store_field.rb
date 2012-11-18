require 'store_field/version'
require 'store_field/railtie'
require 'active_record'

module StoreField
  extend ActiveSupport::Concern

  module ClassMethods
    def store_field(key, options = {})
      raise ArgumentError, ':in is invalid'     if options[:in] and serialized_attributes[options[:in].to_s].nil?
      raise ArgumentError, ':type is invalid'   if options[:type] and ![ Hash, Set ].include?(options[:type])

      klass = options[:type] || Hash
      store_attribute = options[:in] || serialized_attributes.keys.first
      raise ScriptError, 'store method must be defined before store_field' if store_attribute.nil?

      # Accessor
      define_method(key) do
        value = send(store_attribute)[key]
        if value.nil?
          value = klass.new
          send(store_attribute)[key] = value
        end
        value
      end

      # Utility methods for Hash
      if klass == Hash and options[:keys]
        options[:keys].each do |subkey|
          define_method("#{key}_#{subkey}") do
            send(key)[subkey]
          end

          define_method("#{key}_#{subkey}=") do |value|
            send(key)[subkey] = value
          end
        end
      end

      # Utility methods for Set
      if klass == Set
        define_method("set_#{key}")     {|value| send(key).add(value); self }
        define_method("unset_#{key}")   {|value| send(key).delete(value); self }
        define_method("set_#{key}?")    {|value| send(key).include?(value) }
        define_method("unset_#{key}?")  {|value| !send(key).include?(value) }

        if options[:values]
          validate do
            diff = send(key).to_a - options[:values]
            unless diff.empty?
              errors.add(key, "is invalid with #{diff.inspect}")
            end
          end
        end
      end
    end
  end
end
