class Author < ActiveRecord::Base
  has_many :posts
  has_many :comments
  has_many :pictures, as: :imageable
end

class UglyAuthor < Author
  default_scope { where ugly: true }
end

class Post < ActiveRecord::Base
  has_many :comments
  belongs_to :author
  has_many :author_comments, through: :author, source: :comments

  belongs_to :ugly_author, foreign_key: :author_id
  has_many :ugly_author_comments, through: :ugly_author, source: :comments

  has_many :pictures, as: :imageable

  belongs_to :parent, class_name: 'Post'
  belongs_to :child, class_name: 'Post'
end

class Comment < ActiveRecord::Base
  belongs_to :author
  belongs_to :post
end

class Picture < ActiveRecord::Base
  belongs_to :comment
  belongs_to :imageable, polymorphic: true
end

class ResearchPaper < ActiveRecord::Base
  has_and_belongs_to_many :authors, join_table: :author_research_papers
end
