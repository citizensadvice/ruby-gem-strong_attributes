# frozen_string_literal: true

require "strong_attributes/too_many_records"

module StrongAttributes
  module NestedAttributes
    class NestedArray
      attr_reader :value

      def initialize(form, allow_destroy: false, limit: nil, reject_if: nil, replace: false)
        @form = form
        @allow_destroy = allow_destroy
        @limit = limit
        @reject_if = reject_if
        @replace = replace
      end

      def assign_value(values, context)
        if values.nil?
          @value = values
        else
          values = values.values if values.is_a?(Hash)
          return unless values.is_a?(Enumerable)
          raise TooManyRecords if @limit && values.length > @limit

          if @replace
            @value = []
          else
            @value ||= []
          end
          values.each { |item| set_item(item, context) }
        end
      end

      private

      def set_item(item, context)
        case item
        when @form
          @value << item
        when Hash
          set_attributes(item, context)
        end
      end

      def id_key
        @_id_key = @form.class.try(:primary_key) || "id"
      end

      def find_from_id(value)
        @value.find { |i| i.try(id_key)&.to_s == value[id_key].to_s } if value[id_key].present?
      end

      def set_attributes(item, context)
        item = item.with_indifferent_access
        found = find_from_id(item)
        destroy = @allow_destroy && Helpers.destroy_flag?(item["_destroy"])
        return if @reject_if && Helpers.reject?(item, @reject_if, context)

        if found && destroy && !found.respond_to?(:mark_for_destruction)
          @value.delete(found)
        elsif found
          found.mark_for_destruction if destroy
          found.assign_attributes(item)
        elsif !destroy
          # Add to array
          @value << @form.new(item)
        end
      end
    end
  end
end
