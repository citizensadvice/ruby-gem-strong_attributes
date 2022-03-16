# frozen_string_literal: true

RSpec.describe StrongAttributes do
  describe "setting attributes" do
    context "with a kwarg" do
      it "sets a known attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string
        end

        expect(test_class.new(name: "foo").name).to eq "foo"
      end

      it "sets dirty" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string
        end

        expect(test_class.new(name: "foo").changes).to eq("name" => [nil, "foo"])
      end

      it "does not set an unknown attribute" do
        test_class = Class.new do
          include StrongAttributes
          attr_accessor :unknown

          attribute :name, :string
        end

        expect(test_class.new(unknown: "foo").unknown).to eq nil
      end
    end

    context "with symbol hash key" do
      it "sets a known attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string
        end

        expect(test_class.new({ name: "foo" }).name).to eq "foo"
      end

      it "does not set an unknown attribute" do
        test_class = Class.new do
          include StrongAttributes
          attr_accessor :unknown

          attribute :name, :string
        end

        expect(test_class.new({ unknown: "foo" }).unknown).to eq nil
      end
    end

    context "with string hash key" do
      it "sets a known attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string
        end

        expect(test_class.new({ "name" => "foo" }).name).to eq "foo"
      end
    end
  end

  describe "array attributes" do
    context "when defined explicitly" do
      let(:test_class) do
        Class.new do
          include StrongAttributes
          attribute :name, StrongAttributes::Type::Array.new(type: :string)
        end
      end

      it "creates an attribute that converts items to an array" do
        expect(test_class.new(name: "foo").name).to eq ["foo"]
      end

      it "creates an attribute that saves items as an array" do
        expect(test_class.new(name: %w[foo bar]).name).to eq %w[foo bar]
      end
    end

    context "when defined with :array" do
      let(:test_class) do
        Class.new do
          include StrongAttributes
          attribute :name, :array, :string
        end
      end

      it "creates an attribute that converts items to an array" do
        expect(test_class.new(name: "foo").name).to eq ["foo"]
      end

      it "creates an attribute that saves items as an array" do
        expect(test_class.new(name: %w[foo bar]).name).to eq %w[foo bar]
      end
    end

    context "when defined with :array and explicit sub-type" do
      let(:test_class) do
        Class.new do
          include StrongAttributes
          attribute :name, :array, ActiveModel::Type::String.new
        end
      end

      it "creates an attribute that converts items to an array" do
        expect(test_class.new(name: "foo").name).to eq ["foo"]
      end

      it "creates an attribute that saves items as an array" do
        expect(test_class.new(name: %w[foo bar]).name).to eq %w[foo bar]
      end
    end

    context "when modified in place" do
      let(:test_class) do
        Class.new do
          include StrongAttributes
          attribute :name, :array, :string
        end
      end

      it "creates an attribute that converts items to an array" do
        test = test_class.new(name: "foo")
        test.name << "bar"
        expect(test.name_changed?).to eq true
      end
    end
  end

  describe "calling setters" do
    context "with just kwargs" do
      it "does not call setters" do
        test_class = Class.new do
          include StrongAttributes
          attr_accessor :unsafe
        end

        expect(test_class.new(unsafe: "foo").unsafe).to eq nil
      end
    end

    context "with just a hash" do
      it "does not call setters" do
        test_class = Class.new do
          include StrongAttributes
          attr_accessor :unsafe
        end

        expect(test_class.new({ "unsafe" => "foo" }).unsafe).to eq nil
      end
    end

    context "with a hash and kwargs" do
      it "calls setters" do
        test_class = Class.new do
          include StrongAttributes
          attr_accessor :unsafe
        end

        expect(test_class.new({}, unsafe: "foo").unsafe).to eq "foo"
      end
    end

    context "with an unknown setter" do
      it "raises a NoMethodError" do
        test_class = Class.new do
          include StrongAttributes
        end

        expect do
          test_class.new({}, unknown: "foo").unsafe
        end.to raise_error NoMethodError
      end
    end
  end

  describe ".safe_setter" do
    it "calls allowed setters" do
      test_class = Class.new do
        include StrongAttributes
        attr_accessor :safe
        attr_accessor :other_safe
        attr_accessor :unsafe

        safe_setter :safe, :other_safe
      end

      expect(test_class.new({ safe: "foo", unsafe: "bar", other_safe: "foe" })).to have_attributes(
        safe: "foo",
        other_safe: "foe",
        unsafe: nil
      )
    end

    context "with an already set attribute" do
      it "is not replaced by the default" do
        test_class = Class.new do
          include StrongAttributes

          safe_setter :complex_setter

          attribute :foo, :string, default: "foo"
          attribute :bar, :string, default: -> { "bar" }
          attribute :fee, :boolean, default: -> { true }

          def complex_setter=(value)
            self.foo = value
            self.bar = value
            self.fee = false
          end
        end

        expect(test_class.new).to have_attributes(
          foo: "foo",
          bar: "bar",
          fee: true
        )

        expect(test_class.new(complex_setter: "fizz")).to have_attributes(
          foo: "fizz",
          bar: "fizz",
          fee: false
        )
      end
    end
  end

  describe "setting attributes with defaults" do
    context "with a static default" do
      it "uses the default by default" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: "foo"
        end

        expect(test_class.new.name).to eq "foo"
      end

      it "allows the default to be overridden" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: "foo"
        end

        expect(test_class.new(name: "bar").name).to eq "bar"
      end

      it "does not set dirty" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: "foo"
        end

        expect(test_class.new.changed?).to eq false
      end

      it "does set dirty if overridden" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: "foo"
        end

        expect(test_class.new(name: "bar").changed?).to eq true
      end
    end

    context "with a proc default" do
      it "uses a default with no airity" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: -> { default_value }

          def default_value
            "foo"
          end
        end

        expect(test_class.new.name).to eq "foo"
      end

      it "uses a default with airity" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: -> { default_value }

          def default_value
            "foo"
          end
        end

        expect(test_class.new.changed?).to eq false
      end

      it "does not set dirty" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: -> { "foo" }
        end

        expect(test_class.new.changed?).to eq false
      end

      it "allows the default to be overridden" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: -> { "foo" }
        end

        expect(test_class.new(name: "bar").name).to eq "bar"
      end

      it "does set dirty if overridden" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: -> { "foo" }
        end

        expect(test_class.new(name: "bar").changed?).to eq true
      end

      it "allows defaults to be based on previous attributes" do
        test_class = Class.new do
          include StrongAttributes
          attribute :hello, :string
          attribute :name, :string, default: -> { "#{hello} World!" }
        end

        expect(test_class.new(hello: "Greetings").name).to eq "Greetings World!"
      end
    end

    context "with a symbol default" do
      it "uses a default method" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: :default_value

          def default_value
            "foo"
          end
        end

        expect(test_class.new.name).to eq "foo"
      end

      it "does not set dirty" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: :default_value

          def default_value
            "foo"
          end
        end

        expect(test_class.new.changed?).to eq false
      end

      it "allows the default to be overridden" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: :default_value

          def default_value
            "foo"
          end
        end

        expect(test_class.new(name: "bar").name).to eq "bar"
      end

      it "does set dirty if overridden" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string, default: :default_value

          def default_value
            "foo"
          end
        end

        expect(test_class.new(name: "bar").changed?).to eq true
      end

      it "allows defaults to be based on previous attributes" do
        test_class = Class.new do
          include StrongAttributes
          attribute :hello, :string
          attribute :name, :string, default: :default_value

          def default_value
            "#{hello} World!"
          end
        end

        expect(test_class.new(hello: "Greetings").name).to eq "Greetings World!"
      end
    end
  end

  describe "rails built in attribute types" do
    context "with untyped attribute" do
      it "sets the attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name
        end

        expect(test_class.new(name: "value").name).to eq "value"
      end
    end

    context "with string type" do
      it "sets the attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string
        end

        expect(test_class.new(name: "value").name).to eq "value"
      end
    end

    context "with integer type" do
      it "sets the attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :integer
        end

        expect(test_class.new(name: "1").name).to eq 1
      end
    end

    context "with boolean type" do
      it "sets the attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :boolean
        end

        expect(test_class.new(name: "y").name).to eq true
      end
    end

    context "with date type" do
      it "sets the attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :date
        end

        expect(test_class.new(name: "1981-01-28").name).to eq Date.new(1981, 1, 28)
      end
    end

    context "with datetime type" do
      it "sets the attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :datetime
        end

        expect(test_class.new(name: "1981-01-28T05:30:00").name).to eq DateTime.new(1981, 1, 28, 5, 30)
      end
    end

    context "with decimal type" do
      it "sets the attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :decimal
        end

        expect(test_class.new(name: "1.1").name).to eq 1.1
      end
    end

    context "with float type" do
      it "sets the attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :float
        end

        expect(test_class.new(name: "1.1").name).to eq 1.1
      end
    end
  end

  describe "#assign_attributes" do
    it "sets attributes using a string key" do
      test_class = Class.new do
        include StrongAttributes
        attribute :name, :string
      end

      test = test_class.new
      test.assign_attributes("name" => "foo")
      expect(test.name).to eq "foo"
    end

    it "sets attributes using a symbol key" do
      test_class = Class.new do
        include StrongAttributes
        attribute :name, :string
      end

      test = test_class.new
      test.assign_attributes(name: "foo")
      expect(test.name).to eq "foo"
    end

    it "does not set unknown attributes" do
      test_class = Class.new do
        include StrongAttributes
        attr_accessor :unsafe
      end

      test = test_class.new
      test.assign_attributes(unsafe: "foo")
      expect(test.unsafe).to eq nil
    end

    it "assigns to safe setters" do
      test_class = Class.new do
        include StrongAttributes
        attr_accessor :safe

        safe_setter :safe
      end

      test = test_class.new
      test.assign_attributes(safe: "foo")
      expect(test.safe).to eq "foo"
    end
  end

  describe "#attributes=" do
    it "sets attributes using a string key" do
      test_class = Class.new do
        include StrongAttributes
        attribute :name, :string
      end

      test = test_class.new
      test.attributes = { "name" => "foo" }
      expect(test.name).to eq "foo"
    end

    it "sets attributes using a symbol key" do
      test_class = Class.new do
        include StrongAttributes
        attribute :name, :string
      end

      test = test_class.new
      test.attributes = { name: "foo" }
      expect(test.name).to eq "foo"
    end

    it "does not set unknown attributes" do
      test_class = Class.new do
        include StrongAttributes
        attr_accessor :unsafe
      end

      test = test_class.new
      test.attributes = { unsafe: "foo" }
      expect(test.unsafe).to eq nil
    end

    it "assigns to safe setters" do
      test_class = Class.new do
        include StrongAttributes
        attr_accessor :safe

        safe_setter :safe
      end

      test = test_class.new
      test.attributes = { safe: "foo" }
      expect(test.safe).to eq "foo"
    end
  end

  describe "#attributes" do
    it "is the attributes" do
      test_class = Class.new do
        include StrongAttributes
        attribute :name, :string
      end

      expect(test_class.new(name: "foo").attributes).to eq("name" => "foo")
    end
  end

  describe "#as_json" do
    it "serializers to json" do
      test_class = Class.new do
        include StrongAttributes
        attr_accessor :nested

        safe_setter :nested

        attribute :name, :string

        def test
          "bar"
        end
      end

      test = test_class.new(name: "foo", nested: test_class.new(name: "foe"))
      expect(test.as_json(only: :name, methods: :test, include: :nested)).to eq(
        "name" => "foo",
        "test" => "bar",
        "nested" => {
          "name" => "foe"
        }
      )
    end
  end

  describe "validations" do
    it "validates using active model validations" do
      test_class = Class.new do
        include StrongAttributes

        def self.name
          "Class"
        end

        attribute :name, :string

        validates :name, presence: true
      end

      test = test_class.new
      expect(test.invalid?).to eq true
      expect(test.errors.full_messages).to eq ["Name can't be blank"]
    end

    it "validates numericality" do
      test_class = Class.new do
        include StrongAttributes

        def self.name
          "Class"
        end

        attribute :number, :float

        validates :number, numericality: true
      end

      test = test_class.new(number: "foo")
      expect(test.invalid?).to eq true
      expect(test.errors.full_messages).to eq ["Number is not a number"]
    end

    context "when using shoulda matches" do
      subject do
        Class.new do
          include StrongAttributes

          def self.name
            "Class"
          end

          attribute :name, :string
          validates :name, presence: true
        end.new
      end

      before do
        # Pretty sure this is a bug in shoulda matches
        stub_const("ActiveRecord::Type::Serialized", Class.new)
      end

      it { is_expected.to validate_presence_of :name }
    end
  end

  describe "attribute presence" do
    it "allows presence to be checked" do
      test_class = Class.new do
        include StrongAttributes

        attribute :number, :float
      end

      expect(test_class.new.number?).to eq false
      expect(test_class.new(number: 0).number?).to eq true
    end
  end

  describe "overriding setters" do
    it "allows setters to be overridden" do
      test_class = Class.new do
        include StrongAttributes

        attribute :number, :float

        def number=(value)
          super(value + 1)
        end
      end

      expect(test_class.new(number: 1).number).to eq 2
    end
  end

  describe ".inspect" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        def self.name
          "Test"
        end

        attribute :name, :string
        attribute :number, :float
      end
    end

    it "gives a pretty inspect" do
      expect(test_class.inspect).to eq "Test(name: string, number: float)"
    end
  end

  describe "#inspect" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        def self.name
          "Test"
        end

        attribute :name, :string
        attribute :number, :float
        attribute :date, :date
      end
    end

    it "gives a pretty inspect" do
      expect(test_class.new(name: "foo", date: Date.new).inspect).to eq '#<Test name: "foo", number: nil, date: "-4712-01-01">'
    end
  end
end
