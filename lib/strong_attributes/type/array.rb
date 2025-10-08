# frozen_string_literal: true

module StrongAttributes
  module Type
    # Attribute type for an array of values
    #
    # The value will be coerced to a compacted array.
    # Optionally a type can provided to coerce the array members
    class Array < ActiveModel::Type::Value
      def initialize(type: nil, **)
        @type = case type
                when ActiveModel::Type::Value then type
                when Symbol then ActiveModel::Type.lookup(type)
                else ActiveModel::Type.default_value
                end
        super(**)
      end

      def changed_in_place?(raw_old_value, new_value)
        cast(raw_old_value) != new_value
      end

      def cast(value)
        Array(value).compact.map do |item|
          @type.cast(item)
        end
      end
    end
  end
end
