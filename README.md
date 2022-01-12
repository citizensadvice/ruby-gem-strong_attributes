**WARNING: experimental**

# StrongAttributes

Create a [form object](https://dev.to/drbragg/rails-design-patterns-form-object-4d47)
built from [`ActiveModel::Attributes`](https://www.rubydoc.info/gems/activemodel/ActiveModel/Attributes).

The form can be initialized directly using params from a controller, and only the user data matching
defined attributes will be set.

This gives you type coercion and skips needing to setup your StrongParameters filter, because it is built into the model.

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
#
# @form # => <Form my_string="foo" my_number=1>
```

## Setting defaults

## Overriding setters

## Initializing

It is useful to initialize a model with non-user input.  For example you
might want to pass in model loaded by the controller.

If the form is initialized with an object, then any keyword arguments passed to the form
will be passed to attributes writers.

```ruby
class Form
  include StrongAttributes

  attr_accessor :not_set_by_user
  attr_accessor :safe_from_user

  attribute :my_string, :string
  attribute :my_number, :integer
end

form = Form.new({ my_string: "foo", safe_from_user: "bad_value" }, not_set_by_user: "something")
form.not_set_by_user # => "something"
form.safe_from_user # => nil
```

## Validation

## Custom attributes

## Nested attributes

### Clearing the values

## Safe setters

# TODO

- Add doc comments
- Finish readme
