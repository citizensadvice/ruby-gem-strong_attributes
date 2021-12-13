# frozen_string_literal: true

module StrongAttributes
  module NestedAttributes
    class NestedArray
      attr_reader :value

      def initialize(form)
        @form = form
      end

      def value=(value)
        if value.nil?
          @value = value
        else
          values = values.values if values.is_a?(Hash)
          return unless value.is_a?(Array)

          @value ||= []
          values.each(&method(:set_item))
        end
      end

      private

      def set_item(item)
        case item
        when @form
          @value << item
        when Hash
          item = item.stringify_keys
          found = find_from_id(item)
          if found
            # Existing record, merge in the known attributes
            found.assign_attributes(item)
          else
            # Add to array
            @value << @form.new(item)
          end
        end
      end

      def id_key
        @_id_key = @form.class.try(:primary_key) || "id"
      end

      def find_from_id(value)
        @value.find { |i| i.try(id_key)&.to_s == value[id_key].to_s } if value[id_key].present?
      end
    end
  end
end
