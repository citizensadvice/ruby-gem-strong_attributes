# frozen_string_literal: true

module StrongAttributes
  module NestedAttributes
    class NestedObject
      attr_reader :value

      def initialize(form)
        @form = form
      end

      def value=(value)
        case value
        when nil, @form
          @value = value
        when Hash
          if @value
            # Already initialized, merge in known attributes
            @value.assign_attributes(value)
          else
            # Not initialized, so create a new item
            @value = @form.new(value)
          end
        end
      end
    end
  end
end
