# frozen_string_literal: true

require "strong_attributes/copy_errors"
require "strong_attributes/nested_attributes/nested_object"
require "strong_attributes/nested_attributes/nested_array"

module StrongAttributes
  module NestedAttributes
    extend ActiveSupport::Concern

    class_methods do
      def nested_attributes(name, form = nil, **options, &block)
        _define_nested_attributes(name, NestedObject, form, **options, &block)
      end

      def nested_array_attributes(name, form = nil, **options, &block)
        _define_nested_attributes(name, NestedArray, form, **options, &block)
      end

      private

      def _nested_methods
        # A module to hold the setter methods
        # This will allow them to be overridden by the user and for the user to call super
        @_nested_methods ||= Module.new
      end

      def _define_nested_attributes(name, type, form = nil, default: nil, copy_errors: true, &block) # rubocop:disable Metrics/AbcSize, Metrics/ParameterLists
        form ||= Helpers.create_anonymous_form(name, self.name, &block)
        safe_setter name
        self._nested_attributes = _nested_attributes.merge(name => type.new(form))
        self._attribute_default_procs = _attribute_default_procs.merge(name => default) if default
        _nested_methods.define_method name do
          _nested_attributes[name].value
        end
        _nested_methods.define_method "#{name}=" do |value|
          _nested_attributes[name].value = value
        end
        validates_with CopyErrorsValidator, allow_blank: true, attributes: [name] if copy_errors
      end
    end

    included do
      include _nested_methods
      class_attribute :_nested_attributes, default: {}
    end

    delegate :_nested_attribute, to: :class, private: true
  end
end
