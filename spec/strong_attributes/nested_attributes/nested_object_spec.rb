# frozen_string_literal: true

RSpec.describe StrongAttributes::NestedAttributes::NestedObject do
  it "allows nested attributes with inline definitions" do
    test_class = Class.new do
      include StrongAttributes

      nested_attributes :object do
        attribute :name, :string
      end
    end

    expect(test_class.new(object: { name: "foo" })).to have_attributes(
      object: have_attributes(
        name: "foo",
        class: have_attributes(
          name: "Object"
        )
      )
    )
  end

  it "allows nested attributes with a form definition" do
    test_sub = Class.new do
      include StrongAttributes

      attribute :name, :string
    end

    test_class = Class.new do
      include StrongAttributes

      nested_attributes :object, test_sub
    end

    expect(test_class.new(object: { name: "foo" })).to have_attributes(
      object: have_attributes(
        class: test_sub,
        name: "foo"
      )
    )
  end

  it "allows nested attributes with a form definition as a string" do
    test_sub = Class.new do
      include StrongAttributes

      attribute :name, :string
    end

    stub_const("MyClass", test_sub)

    test_class = Class.new do
      include StrongAttributes

      nested_attributes :object, "MyClass"
    end

    expect(test_class.new(object: { name: "foo" })).to have_attributes(
      object: have_attributes(
        class: test_sub,
        name: "foo"
      )
    )
  end

  it "allows inline definitions with a specified base class" do
    base_class = Class.new do
      include StrongAttributes

      def name
        "Base"
      end

      def foo
        "bar"
      end
    end

    stub_const("MyClass", base_class)

    test_class = Class.new do
      include StrongAttributes

      nested_attributes :object, "MyClass" do
        attribute :name, :string
      end
    end

    test = test_class.new(object: { name: "foo" })
    expect(test).to have_attributes(
      object: have_attributes(
        name: "foo",
        foo: "bar",
        class: have_attributes(
          name: "Object"
        )
      )
    )
    expect(test.object).to be_a(MyClass)
  end

  it "allows nested attributes with an inherited definition" do
    test_parent = Class.new do
      include StrongAttributes

      nested_attributes :inherited_object do
        attribute :name, :string
      end
      nested_attributes :object do
        attribute :foo, :string
      end
    end

    # Sibling class
    Class.new(test_parent) do
      nested_attributes :object do
        attribute :value, :string
      end
    end

    test_class = Class.new(test_parent) do
      nested_attributes :object do
        attribute :name, :string
      end
    end

    # Check inheritance
    test = test_class.new(object: { name: "foo", value: "bar" }, inherited_object: { name: "in" })
    expect(test).to have_attributes(
      object: have_attributes(
        name: "foo"
      ),
      inherited_object: have_attributes(
        name: "in"
      )
    )

    # Check overriding parent
    expect(test.object).not_to respond_to(:foo)

    # Check not inheriting from sibling
    expect(test.object).not_to respond_to(:value)
  end

  it "stores data on the instance" do
    test_class = Class.new do
      include StrongAttributes

      nested_attributes :object do
        attribute :name, :string
      end
    end

    test_class.new(object: { name: "foo" })

    expect(test_class.new(object: { name: "foo" })).to have_attributes(
      object: have_attributes(
        name: "foo"
      )
    )
  end

  it "names inline definitions" do
    test_class = Class.new do
      include StrongAttributes

      nested_attributes :object do
        attribute :name, :string
      end
    end

    expect(test_class.new(object: { name: "foo" }).object.class.name).to eq "Object"
  end

  describe "initial values" do
    it "sets fixed initial values" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, initial_value: { name: "foo" } do
          attribute :name, :string
        end
      end

      expect(test_class.new).to have_attributes(
        object: have_attributes(
          name: "foo"
        )
      )
    end

    it "sets initial values by proc" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, initial_value: -> { { name: "foo" } } do
          attribute :name, :string
        end
      end

      expect(test_class.new).to have_attributes(
        object: have_attributes(
          name: "foo"
        )
      )
    end

    it "sets initial value by method" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, initial_value: :default_value do
          attribute :name, :string
        end

        def default_value
          { name: "foo" }
        end
      end

      expect(test_class.new).to have_attributes(
        object: have_attributes(
          name: "foo"
        )
      )
    end

    it "merges values into the initial value" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, initial_value: { name: "foo" } do
          attribute :name, :string
          attribute :number, :float
        end
      end

      expect(test_class.new(object: { number: 1 })).to have_attributes(
        object: have_attributes(
          number: 1.0,
          name: "foo"
        )
      )
    end
  end

  describe "default value" do
    it "sets a default value" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, default: { name: "foo" } do
          attribute :name, :string
        end
      end

      expect(test_class.new).to have_attributes(
        object: have_attributes(
          name: "foo"
        )
      )
    end

    it "sets default values by proc" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, default: -> { { name: "foo" } } do
          attribute :name, :string
        end
      end

      expect(test_class.new).to have_attributes(
        object: have_attributes(
          name: "foo"
        )
      )
    end

    it "sets default value by method" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, default: :default_value do
          attribute :name, :string
        end

        def default_value
          { name: "foo" }
        end
      end

      expect(test_class.new).to have_attributes(
        object: have_attributes(
          name: "foo"
        )
      )
    end

    it "does not call default if value is set" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, default: -> { raise "Error" } do
          attribute :name, :string
          attribute :number, :float
        end
      end

      expect(test_class.new(object: { number: 1 })).to have_attributes(
        object: have_attributes(
          number: 1.0,
          name: nil
        )
      )
    end

    it "does not call default if value is set to nil" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, default: -> { raise "Error" } do
          attribute :name, :string
          attribute :number, :float
        end
      end

      expect(test_class.new(object: nil)).to have_attributes(
        object: nil
      )
    end
  end

  describe "setting attributes" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_attributes :object do
          attribute :name, :string
          attribute :number, :float
        end
      end
    end

    context "with a hash" do
      it "merges in changes" do
        test = test_class.new(object: { name: "foo" })
        test.object = { number: 0.1 }
        expect(test).to have_attributes(
          object: have_attributes(
            name: "foo",
            number: 0.1
          )
        )
      end
    end

    context "with nil" do
      it "removes values" do
        test = test_class.new(object: { name: "foo" })
        test.object = nil
        expect(test).to have_attributes(
          object: nil
        )
      end
    end

    context "with not a hash" do
      it "ignores value" do
        test = test_class.new(object: { name: "foo" })
        test.object = []
        expect(test).to have_attributes(
          object: have_attributes(
            name: "foo",
            number: nil
          )
        )
      end
    end

    context "with a form object" do
      it "replaces the form" do
        test = test_class.new(object: { name: "foo" })
        test.object = test.object.class.new(number: 0.1)
        expect(test).to have_attributes(
          object: have_attributes(
            name: nil,
            number: 0.1
          )
        )
      end
    end
  end

  describe "overriding setters" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_attributes :object do
          attribute :name, :string
          attribute :number, :float
        end

        def object=(value)
          super(value.merge("name" => "foo"))
        end
      end
    end

    it "allows setters to be overridden" do
      test = test_class.new(object: { number: 0.1 })
      expect(test).to have_attributes(
        object: have_attributes(
          name: "foo",
          number: 0.1
        )
      )
    end
  end

  describe "validation" do
    it "validates the nested attributes" do
      test_class = Class.new do
        include StrongAttributes

        def self.name
          "Form"
        end

        nested_attributes :object, initial_value: {} do
          attribute :name, :string
          attribute :number, :float

          validates :name, :number, presence: true
        end
      end

      test = test_class.new
      expect(test).to be_invalid
      expect(test.errors.full_messages).to eq [
        "Object name can't be blank",
        "Object number can't be blank"
      ]
    end

    context "when copy_errors is false" do
      it "does not validate the nested attributes" do
        test_class = Class.new do
          include StrongAttributes

          def self.name
            "Form"
          end

          nested_attributes :object, initial_value: {}, copy_errors: false do
            attribute :name, :string
            attribute :number, :float

            validates :name, :number, presence: true
          end
        end

        test = test_class.new
        expect(test).to be_valid
      end
    end

    context "when copy_errors is true option" do
      it "validates the nested attributes without allow blank" do
        test_class = Class.new do
          include StrongAttributes

          def self.name
            "Form"
          end

          nested_attributes :object, copy_errors: true do
            attribute :name, :string
            attribute :number, :float

            validates :name, :number, presence: true
          end
        end

        test = test_class.new
        expect(test).to be_invalid
        expect(test.errors.full_messages).to eq [
          "Object can't be blank"
        ]
      end
    end

    context "when copy_errors has the prefix: false option" do
      it "validates the nested attributes without a prefix" do
        test_class = Class.new do
          include StrongAttributes

          def self.name
            "Form"
          end

          nested_attributes :object, default: {}, copy_errors: { prefix: false } do
            attribute :name, :string
            attribute :number, :float

            validates :name, :number, presence: true
          end
        end

        test = test_class.new
        expect(test).to be_invalid
        expect(test.errors.full_messages).to eq [
          "Name can't be blank",
          "Number can't be blank"
        ]
      end
    end

    context "when using shoulda matches" do
      subject do
        Class.new do
          include StrongAttributes

          def self.name
            "Class"
          end

          nested_attributes :object, initial_value: {}, copy_errors: false do
            attribute :name, :string
            validates :name, presence: true
          end
        end.new.object
      end

      before do
        # Pretty sure this is a bug in shoulda matches
        stub_const("ActiveRecord::Type::Serialized", Class.new)
      end

      it { is_expected.to validate_presence_of :name }
    end
  end

  describe "attributes_setter" do
    context "when not set" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_attributes :object do
            attribute :name, :string
          end
        end
      end

      it "creates an attribute setter" do
        expect(test_class.new(object_attributes: { name: "foo" })).to have_attributes(
          object: have_attributes(
            name: "foo",
            class: have_attributes(
              name: "Object"
            )
          )
        )
      end
    end

    context "when false" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_attributes :object, attributes_setter: false do
            attribute :name, :string
          end
        end
      end

      it "does not create an attributes setter" do
        expect(test_class.new(object_attributes: { name: "foo" }).object).to be_nil
      end
    end
  end

  describe "allow_destroy" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_attributes :object, allow_destroy: true do
          attribute :name, :string
        end
      end
    end

    it "sets a value if _destroy is not true" do
      expect(test_class.new(object: { name: "foo", _destroy: "f" })).to have_attributes(
        object: have_attributes(
          name: "foo"
        )
      )
    end

    it "removes the value is _destroy is true" do
      test = test_class.new(object: { name: "foo" })
      test.object = { _destroy: "t" }
      expect(test.object).to be_nil
    end
  end

  describe "reject_if" do
    context "with a proc" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_attributes :object, reject_if: ->(attrs) { attrs["name"] == "foo" } do
            attribute :name, :string
          end
        end
      end

      it "sets a value if proc returns falsey" do
        expect(test_class.new(object: { name: "bar" })).to have_attributes(
          object: have_attributes(
            name: "bar"
          )
        )
      end

      it "does not set a value if proc returns truthy" do
        expect(test_class.new(object: { name: "foo" })).to have_attributes(
          object: nil
        )
      end
    end

    context "with a symbol" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_attributes :object, reject_if: :reject_if? do
            attribute :name, :string
          end

          def reject_if?(attrs)
            attrs["name"] == "foo"
          end
        end
      end

      it "sets a value if proc returns falsey" do
        expect(test_class.new(object: { name: "bar" })).to have_attributes(
          object: have_attributes(
            name: "bar"
          )
        )
      end

      it "does not set a value if proc returns truthy" do
        expect(test_class.new(object: { name: "foo" })).to have_attributes(
          object: nil
        )
      end
    end

    context "with :all_blank" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_attributes :object, reject_if: :all_blank do
            attribute :name, :string
          end
        end
      end

      it "sets a value if attributes" do
        expect(test_class.new(object: { name: "bar" })).to have_attributes(
          object: have_attributes(
            name: "bar"
          )
        )
      end

      it "does not set a value if no attributes" do
        expect(test_class.new(object: { name: "" })).to have_attributes(
          object: nil
        )
      end
    end
  end

  describe "replace" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_attributes :object, replace: true do
          attribute :name, :string
          attribute :height, :float
        end
      end
    end

    it "sets attributes" do
      expect(test_class.new(object: { name: "bar" })).to have_attributes(
        object: have_attributes(name: "bar", height: nil)
      )
    end

    it "replaces all existing attributes" do
      test = test_class.new(object: { name: "bar", height: 1.0 })
      test.object = { name: "foe" }

      expect(test).to have_attributes(
        object: have_attributes(name: "foe", height: nil)
      )
    end

    context "with an initial value" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_attributes :object, replace: true, initial_value: -> { { name: "foo" } } do
            attribute :name, :string
            attribute :height, :float
          end
        end
      end

      it "replaces the initial value" do
        expect(test_class.new(object: { height: 1 })).to have_attributes(
          object: have_attributes(name: nil, height: 1)
        )
      end
    end
  end
end
