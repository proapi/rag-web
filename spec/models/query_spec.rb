require "rails_helper"

RSpec.describe Query, type: :model do
  describe "associations" do
    it "belongs to user" do
      query = Query.reflect_on_association(:user)
      expect(query.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "validates presence of question" do
      query = Query.new(user: create(:user))
      expect(query).not_to be_valid
      expect(query.errors[:question]).to include("can't be blank")
    end

    it "validates presence of user" do
      query = Query.new(question: "test")
      expect(query).not_to be_valid
      expect(query.errors[:user]).to include("must exist")
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:old_query) { create(:query, user: user, created_at: 2.days.ago) }
    let!(:new_query) { create(:query, user: user, created_at: 1.day.ago) }
    let!(:failed_query) { create(:query, :failed, user: user) }
    let!(:successful_query) { create(:query, :successful, user: user) }

    describe ".recent" do
      it "returns queries in descending order by created_at" do
        expect(Query.recent).to eq([ successful_query, failed_query, new_query, old_query ])
      end
    end

    describe ".successful" do
      it "returns only queries with no error" do
        expect(Query.successful).to contain_exactly(old_query, new_query, successful_query)
      end
    end

    describe ".failed" do
      it "returns only queries with errors" do
        expect(Query.failed).to contain_exactly(failed_query)
      end
    end
  end

  describe "#successful?" do
    context "when error is nil" do
      let(:query) { create(:query, error: nil) }

      it "returns true" do
        expect(query.successful?).to be true
      end
    end

    context "when error is present" do
      let(:query) { create(:query, :failed) }

      it "returns false" do
        expect(query.successful?).to be false
      end
    end
  end

  describe "#failed?" do
    context "when error is present" do
      let(:query) { create(:query, :failed) }

      it "returns true" do
        expect(query.failed?).to be true
      end
    end

    context "when error is nil" do
      let(:query) { create(:query, error: nil) }

      it "returns false" do
        expect(query.failed?).to be false
      end
    end
  end
end
