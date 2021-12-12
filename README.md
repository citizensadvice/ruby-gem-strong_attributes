# StrongAttributes

Create a form object using [`ActiveModel::Attributes`](https://www.rubydoc.info/gems/activemodel/ActiveModel/Attributes).

Allows the form to be initialized with the user input, and only inputs matching the defined params will be used.

This works a bit like [Vitus](https://github.com/solnic/virtus) but using ActiveModel 

```ruby
# Define a form
class Form
  include StrongAttributes

  attribute :my_string, :string, default: "new default"
  attribute :my_number, :integer, default: -> { 2 }
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

## Passing non-user input

Any kwargs passed to the form will call setters

```ruby
class Form
  include StrongAttributes

  attr_accessor :not_set_by_user

  attribute :my_string, :string, default: "new default"
  attribute :my_number, :integer, default: -> { 2 }
end

form = Form.new({ my_string: "foo" }, not_set_by_user: "something")
form.not_set_by_user # => "something"

```

# TODO

- Add tests for none nested
- Tests for numeracality validator
- Try with shoulda matchers
- Tests for nested
- Add useful attribute definitions
