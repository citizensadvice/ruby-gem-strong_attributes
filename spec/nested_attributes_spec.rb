# frozen_string_literal: true

RSpec.describe StrongAttributes do
  it "allows nested attributes with inline definitions" do
    test_class = Class.new do
      include StrongAttributes

      nested_attributes :object do
        attribute :name, :string
      end
    end

    expect(test_class.new(object: { name: "foo" })).to have_attributes(
      object: have_attributes(
        name: "foo"
      )
    )
  end

  describe "default values" do
    it "sets fixed defaults" do
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

    it "sets proc defaults" do
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

    it "sets method defaults" do
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

    it "merges values into defaults" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, default: { name: "foo" } do
          attribute :name, :string
          attribute :number, :float
        end
      end

      expect(test_class.new(object: { number: 1 })).to have_attributes(
        object: have_attributes(
          name: "foo",
          number: 1.0
        )
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

        nested_attributes :object, default: {} do
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

    context "when copy_errors if false" do 
      it "does not validate the nested attributes" do
        test_class = Class.new do
          include StrongAttributes

          def self.name
            "Form"
          end

          nested_attributes :object, default: {}, copy_errors: false do
            attribute :name, :string
            attribute :number, :float

            validates :name, :number, presence: true
          end
        end

        test = test_class.new
        expect(test).to be_valid
      end
    end

    context "when using shoulda matches" do
      subject do
        Class.new do
          include StrongAttributes

          def self.name
            "Class"
          end

          nested_attributes :object, default: {}, copy_errors: false do
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
end
