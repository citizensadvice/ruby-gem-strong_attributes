# frozen_string_literal: true

require "strong_attributes/copy_errors"

module StrongAttributes
  module NestedAttributes
    extend ActiveSupport::Concern

    class_methods do
      def nested_attributes(name, type = nil, **options, &block)
        form = define_nested(name, type, **options, &block)
        define_object_attributes_setter(name, form)
      end

      def nested_array_attributes(name, type = nil, **options, &block)
        form = define_nested(name, type, **options, &block)
        define_array_attributes_setter(name, form)
      end

      private

      def define_nested(name, type = nil, default: nil, copy_errors: true, &block)
        raise ArgumentError, "type cannot be used with a block" if type && block

        validates_with CopyErrorsValidator, allow_blank: true, attributes: [name] if copy_errors
        attr_reader name

        self._safe_setters = [*_safe_setters, name]
        self._attribute_default_procs = _attribute_default_procs.merge(name => default) if default
        type ? type.constantize : define_sub_form(name, &block)
      end

      def define_sub_form(name, &block)
        form = Class.new
        form.include StrongAttributes
        # Validation needs a name
        parent_name = self.name
        form.define_singleton_method(:name) { "#{parent_name}_#{name}" }
        form.class_eval(&block)
        form
      end

      def define_object_attributes_setter(name, form)
        define_method "#{name}=" do |values|
          return instance_variable_set("@#{name}", values) if values.nil? || values.is_a?(form)
          return unless values.is_a?(Hash)

          value = public_send(name)
          if value
            # Already initialized, merge in known attributes
            value.assign_attributes(values)
          else
            # Not initialized, so create a new item
            instance_variable_set("@#{name}", form.new(values))
          end
        end
      end

      def define_array_attributes_setter(name, form)
        # this will behave like accepts_nested_attributes_for
        # the values should be an array or a hash which is converted into an array using `.values`
        # Array items must be hashes, or form instances
        define_method "#{name}=" do |values|
          values = values.values if values.is_a?(Hash)
          return instance_variable_set("@#{name}", nil) if values.nil?
          return unless values.is_a?(Array)

          values.each do |value|
            next unless value.is_a?(Hash) || value.is_a?(form)

            instance_variable_set("@#{name}", []) if public_send(name).nil?
            item = public_send(name)
            unless item
              item = []
              instance_variable_set("@#{name}", item)
            end

            next item << value if value.is_a?(form)

            id_key = form.class.try(:primary_key) || "id"
            value = value.stringify_keys
            found = item&.find { |i| i.try(id_key)&.to_s == value[id_key].to_s } if !value.is_a?(form) && value[id_key].present?
            if found
              # Existing record, merge in the known attributes
              found.assign_attributes(value)
            else
              # Add to array
              item << form.new(value)
            end
          end
        end
      end
    end
  end
end
