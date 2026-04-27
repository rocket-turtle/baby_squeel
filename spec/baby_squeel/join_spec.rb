require "spec_helper"

describe BabySqueel::Join do
  let(:association1) { create_association Author, :posts }
  let(:association2) { create_association Post, :comments }

  subject(:join_path) { described_class.new([association1, association2]) }

  describe "#add_to_tree" do
    let(:tree) do
      {}.tap { |hsh| join_path.add_to_tree(hsh) }
    end

    it "propogates down to the associations" do
      expect(association1).to receive(:add_to_tree).and_call_original
      expect(association2).to receive(:add_to_tree)
      join_path.add_to_tree({})
    end

    it "lets the association mutate the tree" do
      posts_join = tree.keys.first
      expect(posts_join.name).to eq(:posts)
    end

    it "recursively adds to the tree" do
      comments_join = tree.values.first.keys.first
      expect(comments_join.name).to eq(:comments)
    end
  end
end
