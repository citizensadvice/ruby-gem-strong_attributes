# frozen_string_literal: true

require "strong_attributes/too_many_records"

module StrongAttributes
  module NestedAttributes
    class NestedArray
      attr_reader :value

      def initialize(form, allow_destroy: false, limit: nil, reject_if: nil)
        @form = form
        @allow_destroy = allow_destroy
        @limit = limit
        @reject_if = reject_if
      end

      def assign_value(values, context)
        if values.nil?
          @value = values
        else
          values = values.values if values.is_a?(Hash)
          return unless values.is_a?(Enumerable)
          raise TooManyRecords if @limit && values.length > @limit

          @value ||= []
          values.each { |item| set_item(item, context) }
        end
      end

      private

      def set_item(item, context)
        case item
        when @form
          @value << item
        when Hash
          item = item.with_indifferent_access
          found = find_from_id(item)
          destroy = @allow_destroy && Helpers.destroy_flag?(item["_destroy"])
          return if @reject_if && Helpers.reject?(item, @reject_if, context)

          if found
            if destroy
              @value.delete(found)
            else
              found.assign_attributes(item)
            end
          elsif !destroy
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
