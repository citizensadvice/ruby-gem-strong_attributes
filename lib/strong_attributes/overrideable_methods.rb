# frozen_string_literal: true

module StrongAttributes
  module OverridableMethods # :nodoc:
    extend ActiveSupport::Concern

    class_methods do
      def _overrideable_methods(&)
        # A module to hold the setter methods
        # This will allow them to be overridden by the user and for the user to call super
        @_overrideable_methods ||= begin
          m = Module.new
          include m

          m
        end

        @_overrideable_methods.module_eval(&)
      end
    end
  end
end
