**WARNING: experimental**

# StrongAttributes

Create a [form object](https://dev.to/drbragg/rails-design-patterns-form-object-4d47)
built from [`ActiveModel::Attributes`](https://www.rubydoc.info/gems/activemodel/ActiveModel/Attributes).

The form can be initialized directly using params from a controller, and only the user data matching defined attributes will be set.

This moves the responsibility for setting up your [`StrongParameters`](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters) filters from the controller to the form object.

Nested models, arrays, and proc/method defaults are also supported.

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

## Nested attributes

A form can have nested objects and arrays of objects.

These are designed to work like [`accepts_nested_attributes_for`](https://api.rubyonrails.org/v7.0.1/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for) on active records and accept many of the same options.

### Nested objects

A form can be made out of nested attributes using `nested_attributes`.

```ruby
# Using an inline defintion
class Form
  include StrongAttributes

  nested_attributes :person do
  	attribute :name, :string
  	attribute :date_of_birth, :date
  end  
end

Form.new({ person: { name: "Bob" } }).person # => <Person name="Bob" age=nil>

# Using a class
class Person
  attribute :name, :string
  attribute :date_of_birth, :date
end

class Form
  include StrongAttributes

  # Can be a String, or the class
  nested_attributes :person, "Person" 
end

# Defining the super class for an inline definition
# Using an inline defintion
class Form
  include StrongAttributes

  nested_attributes :person, ApplicationForm do
  	attribute :name, :string
  	attribute :age, :date
  end  
end
```

Updating nested attributes sets the attributes on the child form

```ruby
class Form
  include StrongAttributes

  nested_attributes :person do
  	attribute :name, :string
  	attribute :date_of_birth, :date
  end  
end

form = Form.new({ person: { name: "Bob" } })
form.attributes = { date_of_birth: "1980-01-01" }
form.person # => <Person date_of_birth=1980-01-01 name="Bob">
```

Setting to nil will remove the object.

```ruby
  form = Form.new({ person: { name: "Bob" } })
  form.person = nil
  form.person # => nil
```

### Nested arrays

Nested attributes also support arrays.  These are designed to work like

```ruby
class Form
  include StrongAttributes

  nested_array_attributes :people do
  	attribute :name, :string
  	attribute :date_of_birth, :date
  end  
end

form = Form.new({ people: [{ name: "Bob" }, { name: "Harry" }] })
form.person # => <Form people=[<Pe]>
```

### `allow_destroy`

Setting this allows `_destroy` to remove an existing nested object or array item.

### `reject_if`

### `limit`

### `replace`

## Param name

## Initializing with non-user values

It is useful to initialize a model with non-user input.  For example you
might want to pass in model loaded by the controller.

Any keyword arguments passed to the constructor will be passed directly to a setter on the model.

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

## Validation

## Custom attributes

### Array attributes

# TODO

- Add doc comments
- Finish readme
- Check debug name of a nested model
