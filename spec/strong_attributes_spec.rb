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

    context "with strong params" do
      it "sets a known attribute" do
        test_class = Class.new do
          include StrongAttributes
          attribute :name, :string
        end

        # rubocop:disable RSpec/VerifiedDoubles
        param = double("ActionController::Parameters", permit!: { name: "foo" })
        params = double("ActionController::Parameters", require: param)
        # rubocop:enable RSpec/VerifiedDoubles
        expect(test_class.new(params, param_name: "namespace").name).to eq "foo"
        expect(params).to have_received(:require).with("namespace")
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

        expect(test_class.new({ unsafe: "foo" }).unsafe).to eq nil
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
          attribute :name, :string, default: "foo"
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
        end

        expect(test_class.new(name: "bar").name).to eq "bar"
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
  end

  describe "attribute presences" do
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
end
