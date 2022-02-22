# frozen_string_literal: true

module StrongAttributes
  module Helpers # :nodoc:
    def self.create_anonymous_form(name, parent_name, base_class, &block)
      form = Class.new(base_class || Object)
      form.include StrongAttributes unless base_class&.include?(StrongAttributes)
      # Validation needs a name
      form.define_singleton_method(:name) { "#{parent_name}#{name&.to_s&.classify&.singularize}" }
      form.class_eval(&block)
      form
    end

    def self.default_value(name, value, context)
      return value.arity.positive? ? context.instance_exec(name, &value) : context.instance_exec(&value) if value.is_a? Proc
      return context.__send__(value) if value.is_a? Symbol

      value
    end

    def self.destroy_flag?(destroy)
      ActiveModel::Type::Boolean.new.cast(destroy)
    end

    def self.reject?(attributes, value, context)
      case value
      when :all_blank
        attributes.all? { |_, v| v.blank? }
      when Symbol
        context.__send__(value, attributes)
      when Proc
        context.instance_exec(attributes, &value)
      else
        value
      end
    end
  end
end
