require 'spec_helper'

module Polyamorous
  describe "ActiveRecord Compatibility", :polyamorous do
    it 'works with self joins and includes' do
      parent_post = Post.create!
      post = Post.create!(parent: parent_post)

      posts = Post.joins(:parent).includes(:parent, :child)
      db_post = posts.first

      expect(db_post).to eq(post)
      expect(post.child).to be_nil
      expect(post.parent).to eq(parent_post)
    end
  end
end
