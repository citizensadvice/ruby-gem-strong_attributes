# frozen_string_literal: true

require "active_model"
require "active_support"
require "strong_attributes/version"
require "strong_attributes/nested_attributes"

module StrongAttributes
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON
  include ActiveModel::Dirty
  include NestedAttributes

  class_methods do
    def attribute(name, type = ActiveModel::Type::Value.new, **options)
      if options[:default].is_a?(Proc) || options[:default].is_a?(Symbol)
        self._attribute_default_procs = _attribute_default_procs.merge(name => options.delete(:default))
      end
      super
    end

    def safe_setter(*names)
      self._safe_setters = [*_safe_setters, *names.map(&:to_s)]
    end
  end

  included do
    attribute_method_suffix "?", "_before_type_cast", "_came_from_user?"
    class_attribute :_attribute_default_procs, default: {}
    class_attribute :_safe_setters, default: []
  end

  def initialize(attributes = nil, param_name: nil, **kwargs)
    kwargs.each { |k, v| __send__(:"#{k}=", v) } if attributes
    attributes = attributes.require(param_name).permit! if param_name
    attributes ||= kwargs
    super _filter_attributes(attributes)
    _set_defaults(attributes)
  end

  def assign_attributes(attributes)
    super _filter_attributes(attributes)
  end
  alias attributes= assign_attributes

  private

  delegate :_attribute_default_procs, :_safe_setters, to: :class

  # Used by the numericality validator
  def attribute_before_type_cast(attr_name)
    @attributes[attr_name].value_before_type_cast
  end

  # Used by the numericality validator
  def attribute_came_from_user?(attr_name)
    @attributes[attr_name].came_from_user?
  end

  def attribute?(attr_name)
    attributes[attr_name].present?
  end

  def _set_defaults(attributes)
    _attribute_default_procs.without(*attributes.keys.map(&:to_sym)).each do |name, value|
      value = _default_value(name, value)
      if @attributes.key?(name.to_s)
        @attributes.write_from_database(name.to_s, value)
      else
        public_send("#{name}=", value)
      end
    end
  end

  def _filter_attributes(attributes)
    attributes.to_h.with_indifferent_access.slice(*safe_setters)
  end

  def safe_setters
    self.class._default_attributes.keys + _safe_setters
  end

  def _default_value(name, value)
    return value.arity.positive? ? instance_exec(name, &value) : instance_exec(&value) if value.is_a? Proc
    return __send__(value) if value.is_a? Symbol

    value
  end
end
