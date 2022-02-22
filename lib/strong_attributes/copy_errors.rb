# frozen_string_literal: true

module StrongAttributes
  # Copy errors from a model, or array of models
  #
  # To customise error messages using I18n see
  # https://bigbinary.com/blog/rails-6-allows-to-override-the-activemodel-errors-full_message-format-at-the-model-level-and-at-the-attribute-level
  #
  # By default the errors will have the names :"model.attribute", or :"model[0].attribute"
  # This matches how nested attributes errors are named
  class CopyErrorsValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, values)
      return record.errors.add(attribute, :blank) if values.blank?

      Array(values).each_with_index do |value, index|
        next if value.valid?(record.validation_context)

        value.errors.each do |error|
          # See https://github.com/rails/rails/blob/6-1-stable/activerecord/lib/active_record/autosave_association.rb#L358
          record.errors.import(error, attribute: attribute_name(error, attribute, values.is_a?(Array) ? index : nil))
        end
      end
    end

    private

    def attribute_name(error, name, index)
      return "#{name}[#{index}].#{error.attribute}" if index

      "#{name}.#{error.attribute}"
    end
  end
end
