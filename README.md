# StrongAttributes

Create a [form object](https://dev.to/drbragg/rails-design-patterns-form-object-4d47)
built from [`ActiveModel::Attributes`](https://www.rubydoc.info/gems/activemodel/ActiveModel/Attributes).

This is similar to [Virtus](https://github.com/solnic/virtus) and its successors, but specfically built for Rails.

The form can be initialized directly using the user submitted `params` from a controller. Only the user data matching defined attributes will be set and the submitted data will be automatically type cast.

This moves the responsibility for setting up your [`StrongParameters`](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters) filters from the controller to the form object.

Nested models, arrays, and proc/method defaults are supported.

```ruby
# Define a form
class Form
  include StrongAttributes

  attribute :my_string, :string, default: "new default"
  attribute :my_number, :integer, default: :some_method
end

# Define a controller
class MyController < ApplicationController
  def create
    @form = Form.new(params.require(:name).permit!)
  end
end

# POST /my/new
# name[:my_string] = "foo"
# name[:my_number] = "1"
# name[:not_allowed] = "danger"

@form # => <Form my_string="foo" my_number=1>
```

## Attributes

Attributes are set using the Rails [attributes API](https://api.rubyonrails.org/classes/ActiveModel/Attributes/ClassMethods.html).

`StrongAttributes` includes ActiveModel validations and AdviceModel dirty.

There are a number of [built-in types](https://github.com/rails/rails/tree/main/activemodel/lib/active_model/type): `string`, `float`, `decimal`, `integer`, `time`, `boolean`, `binary`, `date`, `datetime`.

You can also create your own.

```ruby
class Form
  include StrongAttributes

  attribute :my_string, :string
  attribute :my_number, :integer
end
```

## Initializing

The form is intended to be initialized with user submitted data. Only defined attributes will be set.

```ruby
class Form
  include StrongAttributes

  attribute :string, :string, default: "new default"
  attribute :number, :integer, default: :some_method
end

# Unknown attributes are ignored
form = Form.new(string: "foo", number: "1", unknown: "bar")
form # => <Form string="foo" number=1>
```

You can also initialize with `ActionController::Parameters` and these will automatically be marked as permitted.

```
# { "bar" => { "string" => "foo", "number" => 1 } }
form = Form.new(params.require(:foo))
# equivalent of `Form.new(params.require(:foo).permit!.to_hash)`
form # => <Form string="foo" number=1>
```

### Initializing with non-user values

It is useful to initialize a form with non-user input. For example you
might want to pass in model loaded by the controller, but not allow potentially unsafe user input to set this value.

If the object is initialized with a hash, and keyword arguments, any keyword arguments passed to the constructor will be passed directly to setters on the model.

```ruby
class Form
  include StrongAttributes

  attr_accessor :not_set_by_user
  attr_accessor :safe_from_user

  attribute :my_string, :string
  attribute :my_number, :integer
end

form = Form.new(
  { my_string: "foo", safe_from_user: "bad_value" },
  not_set_by_user: "something"
)
form.not_set_by_user # => "something"
form.safe_from_user # => nil

# If you want to set non-user values you must supply a hash as the first value
Form.new(safe_from_user: "foo").safe_from_user # => nil
Form.new({}, safe_from_user: "foo").safe_from_user # => "foo"
```

### Safe setters

It is possible to mark a setter as "safe". It will then by initialized with user provided values.

```ruby
class Form
  include StrongAttributes

  attr_accessor :safe_from_user_setter
  attr_accessor :custom_setter
  safe_setter :custom_setter
end

Form.new({ safe_from_user_setter: "foo" }).safe_from_user_setter # => nil
Form.new({ custom_setter: "foo" }).custom_setter # => "foo"
```

## Validation

`StrongAttributes` includes ActiveModel validations.

```ruby
class Form
  include StrongAttributes

  attribute :name, :string

  validates :name, presence: true
end

form = Form.new
form.valid? # => false
form.errors.full_messages # => ["Form Name can't be blank"]
```

## Setting defaults

Attributes can have defaults set as either as a constant, proc or method.

```ruby
# As a constant
class Form
  include StrongAttributes

  attribute :my_string, :string, default: "new default"
end

Form.new.my_string # => "new default"

# As a proc
class Form
  include StrongAttributes

  attribute :my_string, :string, default: ->(name) { "new default" }
end

Form.new.my_string # => "new default"

# As a method
class Form
  include StrongAttributes

  attribute :message, :string, default: :default_message

  private

  def default_message
    "Hello world!"
  end
end

Form.new.message # => "Hello World!"
```

## Overriding setters

You can override attriute setters if the setter needs more complex logic.

Note the setter is called before the value is cast to the attribute type.

```ruby
class Form
  include StrongAttributes

  attribute :postcode, :string

  def postcode=(value)
    super value&.upcase
  end
end
```

## Custom attributes

You can create your own custom attributes using ActiveModel attributes.

```ruby
class StrippedString < ActiveModel::Type::String
  def case(value)
    super(value)&.strip
  end
end

class Form
  include StrongAttributes

  attribute :postcode, StrippedString.new
end
```

## Array attributes

This library extends the `attribute` syntax to allow the definition of array attributes.

```ruby
class Form
  include StrongAttributes

  # This is a shortcut for
  # attribute :numbers, StrongAttributes::Type::Array.new(type: :string)
  attribute :numbers, :array, :string
  # You can also use a positional argument to set the array type
  # attribute :numbers, :array, type: :string
end

Form.new({ numbers: %w[one two]).numbers # => ["one", "two"]
```

## Getting only the changed attributes

`attributes_from_user` allows you to just get the attributes provided by the user, and defaults, and not any unset attributes.

```ruby
class Form
  include StrongAttributes

  attribute :foo, :string
  attribute :fizz, :string
end

# "fizz" attribute is not included as it wasn't set
Form.new({ foo: "bar" }).attributes_from_user # => { "foo" => "bar" }
```

## Nested objects

You can include nested models in the form using `nested_attributes`.

These are intended to work like [ActiveRecord nested attributes](https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html) and support many of the same options.

They can be defined using both in an inline definition, and using concrete classes.

```ruby
# Using an inline defintion
class Form
  include StrongAttributes

  nested_attributes :person do
    attribute :name, :string, default: :default_name
    attribute :date_of_birth, :date

    # This is passed to class_eval, you can add methods and validations here

    validates :name, presence: true

    def default_name
      "Frank"
    end
  end
end

Form.new({ person: { name: "Bob" } }).person # => <Person name="Bob" age=nil>

# Using a class
class Person
  include StrongAttributes

  attribute :name, :string
  attribute :date_of_birth, :date
end

class Form
  include StrongAttributes

  # Can be a String, or the class
  nested_attributes :person, "Person"
end

# Defining the super class for an inline definition
class Form
  include StrongAttributes

  nested_attributes :enhanced_person, Person do
    attribute :superpower, :string
  end
end
```

### Updating nested attributes

A setter is created for the nested attributes. Updates to the will merge in the new values, unless the `replace` option is set to `true`

```ruby
class Form
  include StrongAttributes

  nested_attributes :person do
    attribute :name, :string
    attribute :date_of_birth, :date
  end
end

form = Form.new({ person: { name: "Bob" } })
form.person = { date_of_birth: "1980-01-01" }
form.person # => <Person date_of_birth=1980-01-01 name="Bob">
```

A `name_attributes=` setter is also created. This allows better compatibility with the Rails helper `fields_for`, which is hard coded to look for the a `name_attributes=` setter.

```ruby
form = Form.new({ person: { name: "Bob" } })
form.person_attributes = { date_of_birth: "1980-01-01" }
form.person # => <Person date_of_birth=1980-01-01 name="Bob">
```

Setting to nil will remove the object.

```ruby
  form = Form.new({ person: { name: "Bob" } })
  form.person = nil
  form.person # => nil
```

If `allow_destroy` is set to `true` passing the `_destroy` key will remove the object.

```ruby
class Form
  include StrongAttributes

  nested_attributes :person, allow_destroy: true do
    attribute :name, :string
  end
end

form = Form.new({ person: { name: "Bob" } })
form.person = { _destroy: true }
form.person # => nil
```

### Initial value

Initial values can be set using a proc, or symbol referring to a method.

This is called before the value is set by the user.

```ruby
class Form
  include StrongAttributes

  nested_attributes :person, initial_value: -> { { name: "Bob" } } do
    attribute :name, :string
    attribute :date_of_birth, :date
  end
end

form = Form.new(person: { date_of_birth: "1980-01-01" } })
form.person # => <Person date_of_birth=1980-01-01 name="Bob">
```

### Default value

The default value can be set using a proc, or symbol referring to a method.

This is only called if no value is set by the user.

```ruby
class Form
  include StrongAttributes

  nested_attributes :person, default: -> { { name: "Bob" } } do
    attribute :name, :string
    attribute :date_of_birth, :date
  end
end

form = Form.new
form.person # => <Person date_of_birth=nil name="Bob">
```

### Options

- **`initial_value`**: The initial value, can be a value, proc or a symbol
- **`default`**: The default value if no value is set, can be a value, proc or a symbol
- **`allow_destroy`** (`boolean`): if `true` if a `_destroy: true` key is passed then an existing record will be set to `nil`, or `mark_for_destruction`, will be called if the object responds to that method.
- **`reject_if`** (`proc`): if the proc returns true the update will be rejected/
- **`replace`** (`boolean`): if `true` an update will replace the existing record rather than merging values in.
- **`copy_errors`** (`boolean` | `object`): settings for copying errors. Defaults to `allow_blank: true`. See `CopyErrorsValidator`
- **`attributes_setter`** (`boolean`): if `false` do not create a `name_attributes=` setter.

## Nested arrays

Nested attributes also support arrays. These are designed to work like ActiveRecord nested attributes for `has_many` records.

```ruby
class Form
  include StrongAttributes

  nested_array_attributes :people do
    attribute :name, :string
    attribute :date_of_birth, :date
  end
end

form = Form.new({ people: [{ name: "Bob" }, { name: "Harry" }] })
form.people # => [<Person name="Bob">, <Person name="Harry">]
```

### Updating nested arrays

Updates to nested array attributes work like ActiveRecord nested attributes.

The updates can either be an array or hash. If it is a hash only the values are used.

```ruby
class Form
  include StrongAttributes

  nested_array_attributes :people do
    attribute :name, :string
  end
end

# You can update using an array
form = Form.new
form.people = [{ name: "Bob" }, { name: "Harry" }]
form.people # => [<Person name="Bob">, <Person name="Harry">]

# Or using a hash
form = Form.new
form.people = { "1" => { name: "Bob" }, "2" => { name: "Harry" } }
form.people # => [<Person name="Bob">, <Person name="Harry">]

# New records are appended, unless the `replace` option is set to true
form = Form.new(people: [name: "Bob"])
form.people = [name: "Harry"]
form.people # => [<Person name="Bob">, <Person name="Harry">]
```

If an `id` attribute is present it will update the record with the same id. It supports using `primary_key` to customise this id.

```ruby
class Form
  include StrongAttributes

  nested_array_attributes :people do
    attribute :id, :integer
    attribute :name, :string
  end
end

form = Form.new(people: [id: 1, name: "Bob"])
form.people = [id: 1, name: "Harry"]
form.people # => [<Person id=1 name="Harry">]
```

An `name_attributes=` setter is also created. This allows better compatibility with the Rails helper `fields_for`, which is hard coded to look for the a `name_attributes=` setter.

```ruby
form = Form.new({ people: [name: "Bob"] })
form.people_attributes = [name: "Harry"]
form.people # => [<Person id=1 name="Harry">]
```

If `allow_destroy` is set to true the `_destroy` key can be used to remove a record.

```ruby
class Form
  include StrongAttributes

  nested_array_attributes :people, allow_destroy: true do
    attribute :id, :integer
    attribute :name, :string
  end
end

form = Form.new(people: [{ id: 1, name: "Bob" }, { id: 2, name: "Harry }])
form.people = [id: "1", _destroy: true]
form.people # => [<Person id=2 name="Harry">]
```

### Initial values

Initial values can be set using a proc, or symbol referring to a method.

This is called before the value is set by the user.

```ruby
class Form
  include StrongAttributes

  nested_array_attributes :people, initial_value: -> { [name: "Frank"] } do
    attribute :name, :string
    attribute :date_of_birth, :date
  end
end

form = Form.new({ people: [name: "Bob"] })
form.people # => [<Person name="Bob">, <Person name="Frank">]
```

### Default value

The default value can be set using a proc, or symbol referring to a method.

This is only called if no value is set by the user.

```ruby
class Form
  include StrongAttributes

  nested_array_attributes :people, default: -> { [name: "Frank"] } do
    attribute :name, :string
    attribute :date_of_birth, :date
  end
end

form = Form.new()
form.people # => [<Person name="Frank">]
```

### Options

- **`initial_value`**: The initial value, can be a value, proc or a symbol
- **`default`**: The default value if not value is set, can be a value, proc or a symbol
- **`allow_destroy`** (`boolean`): if `true` if a `_destroy: true` key is passed then an existing record will either be removed, or `mark_for_destruction`, will be called if the object responds to that method.
- **`reject_if`** (`proc`): If the proc returns true the update will be rejected
- **`limit`** (`Integer`): If provided, raise a `TooManyRecords` error if the limit is exceeded
- **`replace`** (`boolean`): if `true` an update will replace the existing record rather than merging values in.
- **`copy_errors`** (`boolean` | `object`): settings for copying errors. Defaults to `allow_blank: true`. See `CopyErrorsValidator`
- **`attributes_setter`** (`boolean`): if `false` do not create a `name_attributes=` setter.

## `CopyErrorsValidator`

This validator will copy errors from a nested model.

By default, it is automatically set when using `nested_array_attributes` or `nested_attributes`
with the option `allow_blank: true`

```ruby
class Form
  include StrongAttributes

  nested_attributes :people, default: {} do # the same as setting `copy_errors: { allow_blank: true }
    attribute :name, :string
  end
end

form = Form.new()
form.valid? # => false
form.errors.full_messages # => ["People name can't be blank"]
```

It can be customised by passing options as you would with a Rails `EachValidator`.

Setting `copy_errors: false` will not set the validator.

You can also use it on other attributes:

```ruby
class Form
  include StrongAttributes

  attr_accessor :model

  validates :model, copy_errors: true
end

form = Form.new()
form.valid? # => false
form.errors.full_messages # => ["Model can't be blank"]
```

### prefix

If the prefix option is set to false, then nested attribute names will not include the model name.

```ruby
class Form
  include StrongAttributes

  nested_attributes :people, default: {}, copy_errors: { prefix: false } do
    attribute :name, :string
  end
end

form = Form.new()
form.valid? # => false
form.errors.full_messages # => ["Name can't be blank"]
```
