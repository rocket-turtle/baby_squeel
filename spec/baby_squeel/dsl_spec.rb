require 'spec_helper'
require 'shared_examples/table'
require 'shared_examples/relation'
require 'baby_squeel/dsl'

describe BabySqueel::DSL do
  subject(:dsl) { create_dsl Post }

  it_behaves_like 'a relation' do
    subject(:table) { dsl }
  end

  it_behaves_like 'a table' do
    subject(:table) { dsl }
  end

  describe '#evaluate' do
    context 'when an arity is given' do
      it 'yields itself' do
        dsl.evaluate do |table|
          expect(table).to be_a(BabySqueel::DSL)
        end
      end

      it 'does not change self' do
        this = self
        that = nil
        dsl.evaluate { |_t| that = self }
        expect(that).to equal(this)
      end
    end

    context 'when no arity is given' do
      it 'changes self' do
        this = self
        that = nil
        dsl.evaluate { that = self }
        expect(that).not_to equal(this)
      end

      it 'resolves attributes without a receiver' do
        resolution = nil
        dsl.evaluate { resolution = title }
        expect(resolution).to be_an(Arel::Attributes::Attribute)
      end
    end
  end
end
