describe BabySqueel::Nodes::Proxy do
  let(:fake_node) { "FakeNode" }
  subject(:proxy) { described_class.new(fake_node) }

  describe "#initialize" do
    it "unwraps other proxy instances" do
      wrapped = described_class.new(proxy)
      expect(wrapped._arel).not_to respond_to(:_arel)
    end
  end

  describe "#inspect" do
    it "includes BabySqueel" do
      expect(proxy.inspect).to match(/BabySqueel{"FakeNode"}/)
    end
  end

  describe "#arel" do
    it "returns the original object" do
      expect(proxy._arel).to eq(fake_node)
    end
  end

  describe "#respond_to?" do
    it "responds to _arel" do
      is_expected.to respond_to(:_arel)
    end

    it "acts like what it eats" do
      is_expected.to respond_to(:downcase)
    end
  end

  describe "#method_missing" do
    it "is what it eats" do
      is_expected.to be_a(String)
    end

    it "raises on undefined methods" do
      expect { proxy.bbbbbbb }.to raise_error(NoMethodError)
    end

    context "when the return value's class is within the Arel namespace" do
      let(:proxy) { described_class.new(Post.arel_table[:id]) }

      it "wrapps it in a new proxy" do
        expect(proxy.eq(nil)).to respond_to(:_arel)
      end
    end

    context "when the return value's class is not within the Arel namespace" do
      it "does not wrap it in a new proxy" do
        expect(proxy.downcase).not_to respond_to(:_arel)
      end
    end
  end
end
