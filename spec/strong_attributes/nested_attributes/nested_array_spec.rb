# frozen_string_literal: true

RSpec.describe StrongAttributes::NestedAttributes::NestedArray do
  it "allows nested attributes with inline definitions" do
    test_class = Class.new do
      include StrongAttributes

      nested_array_attributes :array do
        attribute :name, :string
      end
    end

    expect(test_class.new(array: [name: "foo"])).to have_attributes(
      array: match([
        have_attributes(
          name: "foo"
        )
      ])
    )
  end

  it "allows nested attributes with a form definition" do
    test_sub = Class.new do
      include StrongAttributes

      attribute :name, :string
    end

    test_class = Class.new do
      include StrongAttributes

      nested_array_attributes :array, test_sub
    end

    expect(test_class.new(array: [name: "foo"])).to have_attributes(
      array: match([
        have_attributes(
          name: "foo",
          class: test_sub
        )
      ])
    )
  end

  describe "default values" do
    it "sets fixed defaults" do
      test_class = Class.new do
        include StrongAttributes

        nested_array_attributes :array, default: [name: "foo"] do
          attribute :name, :string
        end
      end

      expect(test_class.new).to have_attributes(
        array: match([
          have_attributes(
            name: "foo"
          )
        ])
      )
    end

    it "sets proc defaults" do
      test_class = Class.new do
        include StrongAttributes

        nested_array_attributes :array, default: -> { [name: "foo"] } do
          attribute :name, :string
        end
      end

      expect(test_class.new).to have_attributes(
        array: match([
          have_attributes(
            name: "foo"
          )
        ])
      )
    end

    it "sets method defaults" do
      test_class = Class.new do
        include StrongAttributes

        nested_array_attributes :array, default: :default_value do
          attribute :name, :string
        end

        def default_value
          [name: "foo"]
        end
      end

      expect(test_class.new).to have_attributes(
        array: match([
          have_attributes(
            name: "foo"
          )
        ])
      )
    end

    it "merges values into defaults" do
      test_class = Class.new do
        include StrongAttributes

        nested_array_attributes :array, default: [name: "foo"] do
          attribute :name, :string
        end
      end

      expect(test_class.new(array: [name: "bar"])).to have_attributes(
        array: match([
          have_attributes(
            name: "foo"
          ),
          have_attributes(
            name: "bar"
          )
        ])
      )
    end
  end

  describe "setting attributes" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_array_attributes :array do
          attribute :id, :integer
          attribute :name, :string
        end
      end
    end

    context "with an array" do
      it "adds items to the array" do
        test = test_class.new(array: [{ name: "foo" }])
        test.array = [{ name: "bar" }, { name: "foe" }]
        expect(test).to have_attributes(
          array: match([
            have_attributes(name: "foo"),
            have_attributes(name: "bar"),
            have_attributes(name: "foe")
          ])
        )
      end
    end

    context "with nil" do
      it "removes values" do
        test = test_class.new(array: [name: "foo"])
        test.array = nil
        expect(test).to have_attributes(
          array: nil
        )
      end
    end

    context "with not an enumerable" do
      it "ignores values" do
        test = test_class.new(array: [{ name: "foo" }])
        test.array = "foo"
        expect(test).to have_attributes(
          array: match([
            have_attributes(name: "foo")
          ])
        )
      end
    end

    context "with a hash" do
      it "adds the hash values to the array" do
        test = test_class.new(array: [{ name: "foo" }])
        test.array = { x: { name: "bar" } }
        expect(test).to have_attributes(
          array: match([
            have_attributes(name: "foo"),
            have_attributes(name: "bar")
          ])
        )
      end
    end

    context "with an enumerable" do
      it "adds the values to the array" do
        test = test_class.new(array: [{ name: "foo" }])
        test.array = Enumerator.new do |yielder|
          yielder << { name: "bar" }
        end
        expect(test).to have_attributes(
          array: match([
            have_attributes(name: "foo"),
            have_attributes(name: "bar")
          ])
        )
      end
    end

    context "with items with ids" do
      it "matches against existing ids" do
        test = test_class.new(array: [{ name: "foo", id: 1 }])
        test.array = [
          { name: "bar", id: "1" },
          { name: "foe", id: "2" }
        ]
        expect(test).to have_attributes(
          array: match([
            have_attributes(name: "bar", id: 1),
            have_attributes(name: "foe", id: 2)
          ])
        )
      end
    end

    context "with a form object" do
      it "adds items to the array" do
        test = test_class.new(array: [{ name: "foo", id: 1 }])
        form = test.array[0].class.new(name: "bar", id: 1)
        test.array = [form]
        expect(test).to have_attributes(
          array: match([
            have_attributes(
              name: "foo",
              id: 1
            ),
            have_attributes(
              name: "bar",
              id: 1,
              itself: form
            )
          ])
        )
      end
    end

    context "with primary_key" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          def self.primary_key
            "foo"
          end

          nested_array_attributes :array do
            attribute :id, :integer
            attribute :foo, :integer
            attribute :name, :string
          end
        end
      end

      it "matches against the defined primary key" do
        test = test_class.new(array: [{ name: "foo", id: 1, foo: 2 }])
        test.array = [
          { name: "bar", id: "1", foo: "2" },
          { name: "foe", id: "3", foo: "4" }
        ]
        expect(test).to have_attributes(
          array: match([
            have_attributes(name: "bar", id: 1, foo: 2),
            have_attributes(name: "foe", id: 3, foo: 4)
          ])
        )
      end
    end
  end

  describe "overriding setters" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_array_attributes :array do
          attribute :name, :string
          attribute :number, :float
        end

        def array=(value)
          super(value.push("name" => "foo"))
        end
      end
    end

    it "allows setters to be overridden" do
      test = test_class.new(array: [name: "bar"])
      expect(test).to have_attributes(
        array: match([
          have_attributes(name: "bar"),
          have_attributes(name: "foo")
        ])
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

        nested_array_attributes :array, default: [{}] do
          attribute :name, :string
          attribute :number, :float

          validates :name, :number, presence: true
        end
      end

      test = test_class.new
      expect(test).to be_invalid
      expect(test.errors.full_messages).to eq [
        "Array[0] name can't be blank",
        "Array[0] number can't be blank"
      ]
    end

    context "when copy_errors if false" do
      it "does not validate the nested attributes" do
        test_class = Class.new do
          include StrongAttributes

          def self.name
            "Form"
          end

          nested_array_attributes :object, default: {}, copy_errors: false do
            attribute :name, :string
            attribute :number, :float

            validates :name, :number, presence: true
          end
        end

        test = test_class.new
        expect(test).to be_valid
      end
    end
  end

  describe "allow_destroy" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_array_attributes :array, allow_destroy: true do
          attribute :name, :string
          attribute :id, :integer
        end
      end
    end

    it "sets a value if _destroy is not true" do
      expect(test_class.new(array: [name: "foo", _destroy: "f"])).to have_attributes(
        array: match([
          have_attributes(name: "foo")
        ])
      )
    end

    it "removes the value is _destroy is true" do
      test = test_class.new(array: [name: "foo", id: 1])
      test.array = [_destroy: "t", id: "1"]
      expect(test.array).to eq []
    end
  end

  describe "reject_if" do
    context "with a proc" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_array_attributes :array, reject_if: ->(attrs) { attrs["name"] == "foo" } do
            attribute :name, :string
          end
        end
      end

      it "sets a value if proc returns falsey" do
        expect(test_class.new(array: [name: "bar"])).to have_attributes(
          array: match([
            have_attributes(name: "bar")
          ])
        )
      end

      it "does not set a value if proc returns truthy" do
        expect(test_class.new(array: [name: "foo"])).to have_attributes(
          array: []
        )
      end
    end

    context "with a symbol" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_array_attributes :array, reject_if: :reject_if? do
            attribute :name, :string
          end

          def reject_if?(attrs)
            attrs["name"] == "foo"
          end
        end
      end

      it "sets a value if proc returns falsey" do
        expect(test_class.new(array: [name: "bar"])).to have_attributes(
          array: match([
            have_attributes(name: "bar")
          ])
        )
      end

      it "does not set a value if proc returns truthy" do
        expect(test_class.new(array: [name: "foo"])).to have_attributes(
          array: []
        )
      end
    end

    context "with :all_blank" do
      let(:test_class) do
        Class.new do
          include StrongAttributes

          nested_array_attributes :array, reject_if: :all_blank do
            attribute :name, :string
          end
        end
      end

      it "sets a value if attributes" do
        expect(test_class.new(array: [name: "bar"])).to have_attributes(
          array: match([
            have_attributes(name: "bar")
          ])
        )
      end

      it "does not set a value if no attributes" do
        expect(test_class.new(array: [name: ""])).to have_attributes(
          array: []
        )
      end
    end
  end

  describe "limit" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_array_attributes :array, limit: 1 do
          attribute :name, :string
        end
      end
    end

    it "sets under the limit" do
      expect(test_class.new(array: [name: "bar"])).to have_attributes(
        array: match([
          have_attributes(name: "bar")
        ])
      )
    end

    it "raises over the limit" do
      expect do
        test_class.new(array: [{ name: "bar" }, { name: "foo" }])
      end.to raise_error StrongAttributes::TooManyRecords
    end
  end
end
