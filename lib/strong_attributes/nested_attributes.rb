# frozen_string_literal: true

require "strong_attributes/copy_errors"
require "strong_attributes/nested_attributes/nested_object"
require "strong_attributes/nested_attributes/nested_array"

module StrongAttributes
  module NestedAttributes # :nodoc:
    extend ActiveSupport::Concern

    class_methods do # rubocop:disable Metrics/BlockLength
      # Define a nestied form object
      #
      # The form object will accept an inline definition, or a concrete class.
      #
      #   # Inline definition
      #   # A class will be defined and StrongAttributes included
      #   nested_attributes :animal do
      #     attribute :genus, :string
      #   end
      #
      #   # Concrete class
      #   nested_attributes :animal, Animal
      #
      #   # Inline definition with a base class
      #   nested_attributes :animal, BaseAnimal do
      #     attribute :species, :string
      #   end
      #
      # Options are
      #
      # - default - default value, can be a value, proc, or symbol referring to a method name
      # - copy_errors - defaults to `true`, copy validation errors to the parent form during validation
      # - attribute_setter - defaults to `true` - create a `name_attributes=` setter for compatibility with Rails `fields_for` helper
      # - allow_destroy - defaults to `false` - allow the user to use the `_destroy` key to remove the object
      # - refject_if - proc - reject the update if this returns true
      # - replace - defaults to `false` - if true, replace the object instead of merging the values in
      #
      def nested_attributes(name, form = nil, **options, &block)
        _define_nested_attributes(name, NestedObject, form, **options, &block)
      end

      # Define a nested array of form objects
      #
      # The form object will accept an inline definition, or a concrete class.
      #
      #   # Inline definition
      #   # A class will be defined and StrongAttributes included
      #   nested_array_attributes :animals do
      #     attribute :genus, :string
      #   end
      #
      #   # Concrete class
      #   nested_array_attributes :animals, Animal
      #
      #   # Inline definition with a base class
      #   nested_array_attributes :animals, BaseAnimal do
      #     attribute :species, :string
      #   end
      #
      # Options are
      #
      # - default - default value, can be a value, proc, or symbol referring to a method name
      # - copy_errors - defaults to `true`, copy validation errors to the parent form during validation
      # - attribute_setter - defaults to `true` - create a `name_attributes=` setter for compatibility with Rails `fields_for` helper
      # - allow_destroy - defaults to `false` - allow the user to use the `_destroy` key to remove the object
      # - refject_if - proc - reject the update if this returns true
      # - replace - defaults to `false` - if true, replace the array instead of merging the values in
      # - limit - integer - if set, raise TooManyRecords, if the updates exceed this limit
      #
      def nested_array_attributes(name, form = nil, **options, &block)
        _define_nested_attributes(name, NestedArray, form, **options, &block)
      end

      private

      def _nested_methods
        # A module to hold the setter methods
        # This will allow them to be overridden by the user and for the user to call super
        @_nested_methods ||= begin
          m = Module.new
          include m
          m
        end
      end

      def _define_nested_attributes(name, type, form = nil, initial_value: nil, copy_errors: true, attributes_setter: true, **options, &block) # rubocop:disable Metrics/AbcSize, Metrics/ParameterLists, Layout/LineLength
        form = form.constantize if form.is_a? String
        form = Helpers.create_anonymous_form(name, self.name, form, &block) if block_given?
        safe_setter name
        safe_setter "#{name}_attributes" if attributes_setter
        self._nested_attributes = _nested_attributes.merge(name => form)
        self._attribute_initial_procs = _attribute_initial_procs.merge(name => initial_value) if initial_value
        store = :"_nested_attribute_#{name}"
        _nested_methods.module_eval do
          define_method store do
            nested_attributes_store[name] ||= type.new(form, **options)
          end
          private store
          define_method name do
            send(store).value
          end
          define_method "#{name}=" do |value|
            send(store).assign_value(value, self)
          end
          alias_method "#{name}_attributes=", "#{name}=" if attributes_setter
        end
        validates_with CopyErrorsValidator, allow_blank: true, attributes: [name] if copy_errors
      end
    end

    included do
      class_attribute :_nested_attributes, default: {}
    end

    delegate :_nested_attribute, to: :class, private: true

    def nested_attributes_store # :nodoc:
      @nested_attributes_store ||= {}
    end
    private :nested_attributes_store
  end
end
