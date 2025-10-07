require 'spec_helper'

shared_examples_for 'a table' do
  describe '#[]' do
    it 'returns an arel attribute' do
      expect(table[:title]).to be_an(Arel::Attributes::Attribute)
    end
  end

  describe '#on' do
    let(:expr) { table.id.eq(1) }

    it 'sets the on clause' do
      expect(table.on(expr)._on._arel).to eq(expr)
    end

    it 'does not mutate the original instance' do
      expect(table.on(expr).object_id).not_to eq(table.object_id)
    end
  end

  describe '#inner' do
    it 'flags the inner join' do
      expect(table.outer.inner._join).to eq(Arel::Nodes::InnerJoin)
    end

    it 'does not mutate the original instance' do
      expect(table.inner.object_id).not_to eq(table.object_id)
    end
  end

  describe '#outer' do
    it 'flags the outer join' do
      expect(table.outer._join).to eq(Arel::Nodes::OuterJoin)
    end

    it 'does not mutate the original instance' do
      expect(table.outer.object_id).not_to eq(table.object_id)
    end
  end

  describe '#respond_to?' do
    it 'resolves attributes' do
      is_expected.to respond_to(:title)
    end
  end

  describe '#method_missing' do
    it 'resolves attributes' do
      expect(table.id).to be_an(Arel::Attributes::Attribute)
    end

    it 'does not resolve when a block is given' do
      expect { table.id { 'block' } }.to raise_error(NameError)
    end
  end
end
