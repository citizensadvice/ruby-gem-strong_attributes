# frozen_string_literal: true

module StrongAttributes
  module Helpers
    def self.create_anonymous_form(name, parent_name, &block)
      form = Class.new
      form.include StrongAttributes
      # Validation needs a name
      form.define_singleton_method(:name) { "#{parent_name}_#{name}" }
      form.class_eval(&block)
      form
    end

    def self.default_value(name, value, context)
      return value.arity.positive? ? context.instance_exec(name, &value) : context.instance_exec(&value) if value.is_a? Proc
      return context.__send__(value) if value.is_a? Symbol

      value
    end
  end
end
