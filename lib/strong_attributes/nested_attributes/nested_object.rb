# frozen_string_literal: true

module StrongAttributes
  module NestedAttributes # :nodoc:
    class NestedObject
      attr_reader :value

      def initialize(form, name, allow_destroy: false, reject_if: nil, replace: false)
        @form = form
        @name = name
        @allow_destroy = allow_destroy
        @reject_if = reject_if
        @replace = replace
      end

      def assign_value(value, context, initialize_with)
        case value
        when nil, @form
          @value = value
        when Hash
          value = value.with_indifferent_access
          return if @reject_if && Helpers.reject?(value, @reject_if, context)

          if @allow_destroy && Helpers.destroy_flag?(value["_destroy"])
            unless @value.respond_to?(:mark_for_destruction)
              @value = nil
              return
            end
            @value.mark_for_destruction
          end

          if @value && !@replace
            # Already initialized, merge in known attributes
            @value.assign_attributes(value)
          else
            # Not initialized, so create a new item
            @value = @form.new(value, **initalize_options(context, initialize_with))
          end
        end
      end

      private

      def initalize_options(context, initialize_with)
        return {} unless initialize_with

        Helpers.default_value(@name, initialize_with, context) || {}
      end
    end
  end
end
