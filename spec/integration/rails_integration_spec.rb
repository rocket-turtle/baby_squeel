describe "Active Record joins through the gem's JoinDependency#build" do
  context "with a deprecated association", if: BabySqueel::ActiveRecord::VersionHelper.deprecated_associations? do
    around do |example|
      mode = ActiveRecord::Associations::Deprecation.mode
      ActiveRecord::Associations::Deprecation.mode = :raise
      example.run
    ensure
      ActiveRecord::Associations::Deprecation.mode = mode
    end

    it "reports the association when Active Record joins it" do
      expect { Post.joins(:deprecated_comments).to_sql }.to raise_error(ActiveRecord::DeprecatedAssociationError)
    end

    it "reports the association when BabySqueel joins it" do
      expect { Post.joining { deprecated_comments }.to_sql }.to raise_error(ActiveRecord::DeprecatedAssociationError)
    end

    it "reports the association when BabySqueel outer joins it" do
      expect { Post.joining { deprecated_comments.outer }.to_sql }
        .to raise_error(ActiveRecord::DeprecatedAssociationError)
    end
  end

  it "joins an association with a nil value" do
    expect(Post.joins(author: nil).to_sql).to include("INNER JOIN")
  end
end
