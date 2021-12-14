# frozen_string_literal: true

module StrongAttributes
  module Type
    class Array < ActiveModel::Type::Value
      def initialize(type: nil, **options)
        @type = case type
                when ActiveModel::Type::Value then type
                when Symbol then ActiveModel::Type.lookup(type)
                else ActiveModel::Type.default_value
                end
        super(**options)
      end

      def cast(value)
        Array(value).compact.map do |item|
          @type.cast(item)
        end
      end
    end
  end
end
