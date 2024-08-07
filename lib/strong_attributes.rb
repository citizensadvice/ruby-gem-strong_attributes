# frozen_string_literal: true

require "active_model"
require "active_support"
require "strong_attributes/version"
require "strong_attributes/helpers"
require "strong_attributes/nested_attributes"
require "strong_attributes/normalization"
require "strong_attributes/overrideable_methods"
require "strong_attributes/type/array"

module StrongAttributes # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  include OverridableMethods
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON
  include ActiveModel::Dirty
  include NestedAttributes
  include Normalization

  class_methods do
    # Add an attribute to the modal
    #
    # See ActiveModel documentation for Active Model Attribute Methods
    #
    # This also supports setting defaults using procs and methods
    #
    #   attribute :name, :string, default: -> { "Frank" }
    #   attribute :name, :string, default: :default_method
    #
    # Additionally it supports array attributes
    #
    #   attribute :name, :array, :string
    #
    def attribute(name, type = ActiveModel::Type::Value.new, subtype = nil, **options)
      if options[:default].is_a?(Proc) || options[:default].is_a?(Symbol)
        self._attribute_default_procs = _attribute_default_procs.merge(name => options.delete(:default))
      end
      if type == :array
        super(name, Type::Array.new(type: subtype || options.delete(:type)), **options)
      else
        super(name, type, **options)
      end
    end

    # Mark one or more setters as safe
    #
    # When the class is initialized matching keys will be passed to safe setters
    def safe_setter(*names)
      self._safe_setters = [*_safe_setters, *names.map(&:to_s)]
    end

    def inspect # :nodoc:
      # based on https://github.com/rails/rails/blob/v6.1.1/activerecord/lib/active_record/core.rb#L395
      attr_list = attribute_types.map { |name, type| "#{name}: #{type.type || 'object'}" } * ", "
      "#{name}(#{attr_list})"
    end
  end

  included do
    attribute_method_suffix "?", "_before_type_cast", "_came_from_user?"
    class_attribute :_attribute_default_procs, default: {}
    class_attribute :_attribute_initial_procs, default: {}
    class_attribute :_safe_setters, default: []
  end

  # Initialize the form object
  #
  # If initialized with only keyword arguments, or with only a hash, then only
  # defined attributes and safe setters will be initialized from the input
  #
  # If initialized with a hash, and with keyword arguments, then all keyword arguments will be passed
  # directly to the same named setters
  #
  # If initialized with an object responding to `permit!` (eg `ActionController::Parameters`) then `permit!`
  # will automatically be called
  def initialize(attributes = nil, **kwargs)
    attrs ||= attributes || kwargs
    attrs = attrs.permit!.to_hash if attrs.respond_to?(:permit!)
    @attributes = _default_attributes.deep_dup
    kwargs.each { |k, v| __send__(:"#{k}=", v) } if attributes
    _set_initial_values
    assign_attributes(attrs)
    _set_defaults(attrs)
  end

  # Allows you to set all the attributes by passing in a hash of attributes
  #
  # Only attributes, and safe setters will be assigned to
  def assign_attributes(attributes)
    super(_filter_attributes(attributes))
  end
  alias attributes= assign_attributes

  # Return only the attributes set by the user
  def attributes_from_user
    attributes.select { attribute_came_from_user?(_1) }
  end

  def inspect # :nodoc:
    # based on https://github.com/rails/rails/blob/v6.1.1/activerecord/lib/active_record/core.rb#L669
    inspection = if defined?(@attributes) && @attributes
                   self.class.attribute_names.filter_map do |name|
                     "#{name}: #{attribute_for_inspect(name)}" if @attributes.key?(name)
                   end.join(", ")
                 else
                   "not initialized"
                 end

    "#<#{self.class.name} #{inspection}>"
  end

  private

  delegate :_attribute_default_procs, :_attribute_initial_procs, :_safe_setters, :_default_attributes, to: :class, private: true

  # Used by the numericality validator to detect invalid numbers
  def attribute_before_type_cast(attr_name)
    @attributes[attr_name].value_before_type_cast
  end

  # Used by the numericality validator to detect invalid numbers
  def attribute_came_from_user?(attr_name)
    @attributes[attr_name].came_from_user?
  end

  def attribute?(attr_name)
    attributes[attr_name].present?
  end

  def _set_initial_values
    _attribute_initial_procs.each do |name, value|
      value = Helpers.default_value(name, value, self)
      if @attributes.key?(name.to_s)
        @attributes.write_from_database(name.to_s, value)
      else
        public_send(:"#{name}=", value)
      end
    end
  end

  def _set_defaults(attrs)
    _attribute_default_procs.each do |name, value|
      next if attrs.key?(name) || !public_send(name).nil?

      value = Helpers.default_value(name, value, self)
      if @attributes.key?(name.to_s)
        @attributes.write_from_database(name.to_s, value)
      else
        public_send(:"#{name}=", value)
      end
    end
  end

  def _filter_attributes(attributes)
    attributes.to_h.with_indifferent_access.slice(*safe_setters)
  end

  def safe_setters
    _default_attributes.keys + _safe_setters
  end

  def attribute_for_inspect(attr_name)
    value = send(attr_name)
    if value.is_a?(String) && value.length > 50
      "#{value[0, 50]}...".inspect
    elsif value.is_a?(Date) || value.is_a?(Time)
      value.to_s.inspect
    else
      value.inspect
    end
  end
end
