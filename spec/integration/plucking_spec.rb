require 'spec_helper'

describe '#plucking' do
  before do
    [Post, Author].each(&:delete_all)
    a1 = Author.create! name: 'Rick'
    a2 = Author.create! name: 'Flair'
    Post.create! title: 'one', view_count: 1, author: a1
    Post.create! title: 'two', view_count: 1, author: a2
  end

  it 'plucks' do
    result = Post.plucking { title }
    expect(result).to match_array(['one', 'two'])
  end

  it 'plucks with array' do
    result = Post.plucking { [title] }
    expect(result).to match_array(['one', 'two'])
  end

  it 'plucks distinct' do
    result = Post.distinct.plucking { view_count }
    expect(result).to match_array([1])
  end

  it 'plucks with expression' do
    result = Post.plucking { title == 'one' }
    expect(result).to match_array([0, 1])
  end

  it 'plucks association' do
    result = Post.joining { author }.plucking { author.name }
    expect(result).to match_array(['Rick', 'Flair'])
  end
end
