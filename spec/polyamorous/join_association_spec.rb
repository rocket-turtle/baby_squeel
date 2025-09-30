require 'spec_helper'

module Polyamorous
  describe JoinAssociation, :polyamorous do
    let(:join_dependency) { new_join_dependency(Picture, {}) }
    let(:reflection) { Picture.reflect_on_association(:imageable) }
    let(:parent) { join_dependency.send(:join_root) }
    let(:join_association) { new_join_association(reflection, parent.children, Post) }

    subject { new_join_association(reflection, parent.children, Author) }

    it 'leaves the original reflection intact for thread safety' do
      reflection.instance_variable_set(:@klass, Post)
      join_association
        .swapping_reflection_klass(reflection, Author) do |new_reflection|
        expect(new_reflection.options).not_to equal reflection.options
        expect(new_reflection.options).not_to have_key(:polymorphic)
        expect(new_reflection.klass).to eq(Author)
        expect(reflection.klass).to eq(Post)
      end
    end

    it 'sets the polymorphic option to true after initializing' do
      expect(join_association.reflection.options[:polymorphic]).to be(true)
    end
  end
end
