require "rails_helper"

RSpec.describe Rag::QueryService do
  let(:user) { create(:user) }
  let(:question) { "What is the capital of France?" }
  let(:service) { described_class.new(user: user, question: question) }
  let(:client_double) { instance_double(Rag::Client) }

  before do
    allow(Rag::Client).to receive(:new).and_return(client_double)
  end

  describe "#call" do
    context "when question is blank" do
      let(:question) { "" }

      it "returns false" do
        expect(service.call).to be false
      end

      it "does not create a query record" do
        expect { service.call }.not_to change(Query, :count)
      end

      it "does not call the client" do
        allow(client_double).to receive(:query)
        service.call
        expect(client_double).not_to have_received(:query)
      end
    end

    context "when query is successful" do
      let(:response) { { "answer" => "Paris is the capital of France.", "metadata" => "extra" } }

      before do
        allow(client_double).to receive(:query).with(question).and_return(response)
      end

      it "returns true" do
        expect(service.call).to be true
      end

      it "creates a query record" do
        expect { service.call }.to change(Query, :count).by(1)
      end

      it "stores the answer" do
        service.call
        expect(service.query_record.answer).to eq("Paris is the capital of France.")
      end

      it "stores metadata" do
        service.call
        expect(service.query_record.metadata).to eq({ "metadata" => "extra" })
      end

      it "does not store error" do
        service.call
        expect(service.query_record.error).to be_nil
      end

      it "associates the query with the user" do
        service.call
        expect(service.query_record.user).to eq(user)
      end
    end

    context "when client raises ConnectionError" do
      before do
        allow(client_double).to receive(:query)
          .and_raise(Rag::Client::ConnectionError, "Unable to reach RAG service")
      end

      it "returns false" do
        expect(service.call).to be false
      end

      it "sets a user-friendly error message" do
        service.call
        expect(service.error).to eq("Unable to reach the AI service. Please try again later.")
      end

      it "creates a query record with error" do
        expect { service.call }.to change(Query, :count).by(1)
        expect(service.query_record.error).to eq("Unable to reach RAG service")
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error)
        service.call
        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/RAG Query Error for User #{user.id}/)
        )
      end
    end

    context "when client raises TimeoutError" do
      before do
        allow(client_double).to receive(:query)
          .and_raise(Rag::Client::TimeoutError, "Request timed out")
      end

      it "returns false" do
        expect(service.call).to be false
      end

      it "sets a user-friendly error message" do
        service.call
        expect(service.error).to eq("The request took too long. Please try again.")
      end
    end

    context "when client raises AuthenticationError" do
      before do
        allow(client_double).to receive(:query)
          .and_raise(Rag::Client::AuthenticationError, "Auth failed")
      end

      it "returns false" do
        expect(service.call).to be false
      end

      it "sets a user-friendly error message" do
        service.call
        expect(service.error).to eq("Service authentication failed. Please contact support.")
      end
    end

    context "when client raises InvalidResponseError" do
      before do
        allow(client_double).to receive(:query)
          .and_raise(Rag::Client::InvalidResponseError, "Invalid response")
      end

      it "returns false" do
        expect(service.call).to be false
      end

      it "sets a user-friendly error message" do
        service.call
        expect(service.error).to eq("Received an invalid response. Please try again.")
      end
    end

    context "when client raises generic Error" do
      before do
        allow(client_double).to receive(:query)
          .and_raise(Rag::Client::Error, "Something went wrong")
      end

      it "returns false" do
        expect(service.call).to be false
      end

      it "sets a user-friendly error message" do
        service.call
        expect(service.error).to eq("An error occurred while processing your query. Please try again.")
      end
    end
  end

  describe "#success?" do
    context "when query was successful" do
      before do
        allow(client_double).to receive(:query)
          .and_return({ "answer" => "Paris" })
        service.call
      end

      it "returns true" do
        expect(service.success?).to be true
      end
    end

    context "when query failed" do
      before do
        allow(client_double).to receive(:query)
          .and_raise(Rag::Client::Error, "Failed")
        service.call
      end

      it "returns false" do
        expect(service.success?).to be false
      end
    end

    context "when call has not been made" do
      it "returns false" do
        expect(service.success?).to be false
      end
    end
  end

  describe "#answer" do
    context "when query was successful" do
      before do
        allow(client_double).to receive(:query)
          .and_return({ "answer" => "Paris is the capital." })
        service.call
      end

      it "returns the answer" do
        expect(service.answer).to eq("Paris is the capital.")
      end
    end

    context "when query failed" do
      before do
        allow(client_double).to receive(:query)
          .and_raise(Rag::Client::Error, "Failed")
        service.call
      end

      it "returns nil" do
        expect(service.answer).to be_nil
      end
    end
  end
end
