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

    it "replaces defaults" do
      test_class = Class.new do
        include StrongAttributes

        nested_attributes :object, default: { name: "foo" } do
          attribute :name, :string
        end
      end

      expect(test_class.new(object: { name: "bar" })).to have_attributes(
        object: have_attributes(
          name: "bar"
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

  describe "setting initial values" do
    let(:test_class) do
      Class.new do
        include StrongAttributes

        nested_attributes :object do
          attribute :name, :string
          attribute :number, :float
        end

        def object=(value)
          super(name: "foo") unless @object
          super value
        end
      end
    end

    it "allows values to be set" do
      test = test_class.new(object: { number: 0.1 })
      expect(test).to have_attributes(
        object: have_attributes(
          name: "foo",
          number: 0.1
        )
      )
      test.object = { name: "bar" }
      expect(test).to have_attributes(
        object: have_attributes(
          name: "bar",
          number: 0.1
        )
      )
    end
  end
end
