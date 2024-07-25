# frozen_string_literal: true

require "strong_attributes/too_many_records"

module StrongAttributes
  module NestedAttributes # :nodoc:
    class NestedArray
      attr_reader :value

      def initialize(form, name, allow_destroy: false, limit: nil, reject_if: nil, replace: false)
        @form = form
        @name = name
        @allow_destroy = allow_destroy
        @limit = limit
        @reject_if = reject_if
        @replace = replace
      end

      def assign_value(values, context, initialize_with)
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
          values.each { |item| set_item(item, context, initialize_with) }
        end
      end

      private

      def set_item(item, context, initialize_with)
        case item
        when @form
          @value << item
        when Hash
          set_attributes(item, context, initialize_with)
        end
      end

      def id_key
        key = @form.try(:primary_key)
        key == false ? nil : key || "id"
      end

      def find_from_id(value)
        @value.find { |i| i.try(id_key)&.to_s == value[id_key].to_s } if id_key && value[id_key].present?
      end

      def set_attributes(item, context, initialize_with) # /*
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
          @value << @form.new(item, **initalize_options(context, initialize_with))
        end
      end

      def initalize_options(context, initialize_with)
        return {} unless initialize_with

        Helpers.default_value(@name, initialize_with, context) || {}
      end
    end
  end
end
