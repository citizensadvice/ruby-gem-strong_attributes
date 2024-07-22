# frozen_string_literal: true

module StrongAttributes
  module Normalization
    extend ActiveSupport::Concern

    included do
      class_attribute :normalized_attributes, default: Set.new
    end

    class_methods do
      # Declare a normalization for one or more attributes
      #
      # This is not implemented in the same way as ActiveRecord. The normalization
      # is applied as part of the setter and before passing the value to the attribute.
      #
      # If the setter is overriden in the class, normalization will still be applied
      # as part of super
      #
      # ==== Options
      #
      # * +:with+ - The normalization to apply.
      # * +:apply_to_nil+ - Whether to apply the normalization to +nil+ values.
      #   Defaults to +false+.
      #
      # ==== Examples
      #
      #   class User
      #     include StrongAttributes
      #
      #     normalizes :email, with: -> email { email.strip.downcase }
      #
      #     attribute :email, :string
      #   end
      #
      #   user = User.new(email: " CRUISE-CONTROL@EXAMPLE.COM\n")
      #   user.email                  # => "cruise-control@example.com"
      def normalizes(*names, with:, apply_to_nil: false)
        names.each do |name|
          _overrideable_methods do
            define_method :"#{name}=" do |value|
              return super(value) if value.nil? && !apply_to_nil

              super(with.call(value))
            end
          end
        end
      end
    end
  end
end
