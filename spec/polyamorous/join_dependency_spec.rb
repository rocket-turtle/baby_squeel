require 'spec_helper'

module Polyamorous
  describe JoinDependency, :polyamorous do
    context 'with symbol joins' do
      context 'post' do
        subject { new_join_dependency Post, author: :comments }

        it { expect(subject.send(:join_root).drop(1).size).to be(2) }
        it { expect(subject.send(:join_root).drop(1).map(&:join_type).uniq).to eq([Polyamorous::InnerJoin]) }
      end

      context 'author' do
        subject { new_join_dependency Author, posts: :comments }

        it { expect(subject.send(:join_root).drop(1).size).to be(2) }
        it { expect(subject.send(:join_root).drop(1).map(&:join_type).uniq).to eq([Polyamorous::InnerJoin]) }
      end
    end

    context 'with has_many :through association' do
      subject { new_join_dependency Post, :author_comments }

      it { expect(subject.send(:join_root).drop(1).size).to be(1) }
      it { expect(subject.send(:join_root).drop(1).first.table_name).to eq('comments') }
    end

    context 'with outer join' do
      subject { new_join_dependency Post, new_join(:comments, :outer) }

      it { expect(subject.send(:join_root).drop(1).size).to be(1) }
      it { expect(subject.send(:join_root).drop(1).first.join_type).to eq(Polyamorous::OuterJoin) }
    end

    context 'with nested outer joins' do
      subject { new_join_dependency Author, new_join(:posts, :outer) => new_join(:comments, :outer) }

      it { expect(subject.send(:join_root).drop(1).size).to be(2) }
      it { expect(subject.send(:join_root).drop(1).map(&:join_type))
             .to eq([Polyamorous::OuterJoin, Polyamorous::OuterJoin]) }
      it { expect(subject.send(:join_root).drop(1).map(&:join_type).uniq).to eq([Polyamorous::OuterJoin]) }
    end

    context 'with polymorphic belongs_to join' do
      subject { new_join_dependency Picture, new_join(:imageable, :inner, Author) }

      it { expect(subject.send(:join_root).drop(1).size).to be(1) }
      it { expect(subject.send(:join_root).drop(1).first.join_type).to be(Polyamorous::InnerJoin) }
      it { expect(subject.send(:join_root).drop(1).first.table_name).to eq('authors') }
    end

    context 'with polymorphic belongs_to join and nested symbol join' do
      subject { new_join_dependency Picture, new_join(:imageable, :inner, Author) => :comments }

      it { expect(subject.send(:join_root).drop(1).size).to be(2) }
      it { expect(subject.send(:join_root).drop(1).map(&:join_type).uniq).to eq([Polyamorous::InnerJoin]) }
      it { expect(subject.send(:join_root).drop(1).first.table_name).to eq('authors') }
      it { expect(subject.send(:join_root).drop(1)[1].table_name).to eq('comments') }
    end

    context 'with polymorphic belongs_to join and nested join' do
      subject { new_join_dependency Picture, new_join(:imageable, :outer, Author) => :comments }

      it { expect(subject.send(:join_root).drop(1).size).to be(2) }
      it { expect(subject.send(:join_root).drop(1).map(&:join_type))
             .to eq([Polyamorous::OuterJoin, Polyamorous::InnerJoin]) }
      it { expect(subject.send(:join_root).drop(1).first.table_name).to eq('authors') }
      it { expect(subject.send(:join_root).drop(1)[1].table_name).to eq('comments') }
    end
  end
end
