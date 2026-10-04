require "spec_helper"

shared_examples_for "a table" do
  describe "#[]" do
    it "returns an arel attribute" do
      expect(table[:title]).to be_an(Arel::Attributes::Attribute)
    end
  end

  describe "#outer" do
    it "flags the outer join" do
      expect(table.outer._join).to eq(Arel::Nodes::OuterJoin)
    end

    it "does not mutate the original instance" do
      expect(table.outer.object_id).not_to eq(table.object_id)
    end
  end

  describe "#respond_to?" do
    it "resolves attributes" do
      is_expected.to respond_to(:title)
    end

    it "resolves associations" do
      is_expected.to respond_to(:author)
    end
  end

  describe "#association" do
    it "builds a table from the associated class" do
      expect(table.association(:author)).to be_a(BabySqueel::Table)
    end

    it "allows chaining attributes" do
      assoc = table.association :author
      expect(assoc.id).to be_a(Arel::Attributes::Attribute)
    end

    it "raises an error for non-existant associations" do
      expect do
        table.association :non_existent
      end.to raise_error(
        BabySqueel::Error,
        /named 'non_existent'(.+)for Post/
      )
    end
  end

  describe "#method_missing" do
    it "resolves attributes" do
      expect(table.id).to be_an(Arel::Attributes::Attribute)
    end

    it "resolves associations" do
      expect(table.author).to be_a(BabySqueel::Association)
    end

    it "raises a custom error for things that look like columns" do
      expect { table.non_existent_column }
        .to raise_error(BabySqueel::Error, /no column or association named 'non_existent_column'/)
    end

    it "raises a NoMethodError when the wrong number of args are given" do
      expect { table.author(1) }.to raise_error(NoMethodError)
    end

    it "does not resolve when a block is given" do
      expect { table.id { "block" } }.to raise_error(NameError)
    end
  end
end
