require "rails_helper"

RSpec.describe(ApplicationHelper, type: :helper) do
  describe "#button_classes" do
    describe "variants" do
      it "returns primary variant classes by default" do
        classes = helper.button_classes
        expect(classes).to(include("bg-secondary-600"))
        expect(classes).to(include("text-white"))
      end

      it "returns primary variant classes when explicitly set" do
        classes = helper.button_classes(variant: :primary)
        expect(classes).to(include("bg-secondary-600"))
        expect(classes).to(include("text-white"))
        expect(classes).to(include("hover:bg-secondary-700"))
      end

      it "returns secondary variant classes" do
        classes = helper.button_classes(variant: :secondary)
        expect(classes).to(include("bg-neutral-200"))
        expect(classes).to(include("text-neutral-900"))
        expect(classes).to(include("hover:bg-neutral-300"))
      end

      it "returns error variant classes" do
        classes = helper.button_classes(variant: :error)
        expect(classes).to(include("bg-error-600"))
        expect(classes).to(include("text-white"))
        expect(classes).to(include("hover:bg-error-700"))
      end

      it "returns danger variant classes (same as error)" do
        classes = helper.button_classes(variant: :danger)
        expect(classes).to(include("bg-error-600"))
        expect(classes).to(include("text-white"))
        expect(classes).to(include("hover:bg-error-700"))
      end

      it "normalizes invalid variant to primary" do
        classes = helper.button_classes(variant: :invalid)
        expect(classes).to(include("bg-secondary-600"))
      end

      it "normalizes nil variant to primary" do
        classes = helper.button_classes(variant: nil)
        expect(classes).to(include("bg-secondary-600"))
      end
    end

    describe "sizes" do
      it "returns base size classes by default" do
        classes = helper.button_classes
        expect(classes).to(include("px-4"))
        expect(classes).to(include("py-2"))
        expect(classes).to(include("text-base"))
      end

      it "returns small size classes" do
        classes = helper.button_classes(size: :sm)
        expect(classes).to(include("px-3"))
        expect(classes).to(include("py-1.5"))
        expect(classes).to(include("text-sm"))
        expect(classes).to(include("gap-1.5"))
      end

      it "returns base size classes when explicitly set" do
        classes = helper.button_classes(size: :base)
        expect(classes).to(include("px-4"))
        expect(classes).to(include("py-2"))
        expect(classes).to(include("text-base"))
        expect(classes).to(include("gap-2"))
      end

      it "returns large size classes" do
        classes = helper.button_classes(size: :lg)
        expect(classes).to(include("px-6"))
        expect(classes).to(include("py-3"))
        expect(classes).to(include("text-lg"))
        expect(classes).to(include("gap-2"))
      end

      it "normalizes invalid size to base" do
        classes = helper.button_classes(size: :invalid)
        expect(classes).to(include("px-4"))
        expect(classes).to(include("py-2"))
        expect(classes).to(include("text-base"))
      end

      it "normalizes nil size to base" do
        classes = helper.button_classes(size: nil)
        expect(classes).to(include("px-4"))
        expect(classes).to(include("py-2"))
        expect(classes).to(include("text-base"))
      end
    end

    describe "base classes" do
      it "always includes base classes" do
        classes = helper.button_classes
        expect(classes).to(include("inline-flex"))
        expect(classes).to(include("items-center"))
        expect(classes).to(include("justify-center"))
        expect(classes).to(include("rounded-lg"))
        expect(classes).to(include("font-medium"))
        expect(classes).to(include("focus:outline-none"))
        expect(classes).to(include("focus:ring-2"))
        expect(classes).to(include("focus:ring-offset-2"))
        expect(classes).to(include("transition-colors"))
      end
    end

    describe "combinations" do
      it "combines variant and size correctly" do
        classes = helper.button_classes(variant: :secondary, size: :sm)
        expect(classes).to(include("bg-neutral-200"))
        expect(classes).to(include("px-3"))
        expect(classes).to(include("py-1.5"))
      end

      it "combines error variant with large size" do
        classes = helper.button_classes(variant: :error, size: :lg)
        expect(classes).to(include("bg-error-600"))
        expect(classes).to(include("px-6"))
        expect(classes).to(include("py-3"))
      end

      it "combines danger variant with small size" do
        classes = helper.button_classes(variant: :danger, size: :sm)
        expect(classes).to(include("bg-error-600"))
        expect(classes).to(include("px-3"))
        expect(classes).to(include("py-1.5"))
      end
    end

    describe "edge cases" do
      it "handles both invalid variant and size" do
        classes = helper.button_classes(variant: :invalid, size: :invalid)
        expect(classes).to(include("bg-secondary-600"))
        expect(classes).to(include("px-4"))
        expect(classes).to(include("py-2"))
      end

      it "returns a string" do
        classes = helper.button_classes
        expect(classes).to(be_a(String))
      end

      it "includes all required classes in output" do
        classes = helper.button_classes(variant: :primary, size: :base)
        # Should have base classes, variant classes, and size classes
        expect(classes.split.length).to(be > 10)
      end
    end
  end
end

