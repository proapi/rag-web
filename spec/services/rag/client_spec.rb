require "rails_helper"
require "webmock/rspec"

RSpec.describe Rag::Client do
  let(:client) { described_class.new }
  let(:base_url) { ENV["RAG_API_URL"] }
  let(:token) { ENV["RAG_API_TOKEN"] }
  let(:question) { "What is the capital of France?" }

  before do
    stub_const("ENV", ENV.to_hash.merge(
      "RAG_API_URL" => "http://localhost:3001",
      "RAG_API_TOKEN" => "test_token_123"
    ))
  end

  describe "#initialize" do
    context "when RAG_API_TOKEN is not set" do
      before do
        stub_const("ENV", ENV.to_hash.merge("RAG_API_TOKEN" => nil))
      end

      it "raises an AuthenticationError" do
        expect { described_class.new }.to raise_error(
          Rag::Client::AuthenticationError,
          "RAG_API_TOKEN is not configured"
        )
      end
    end

    context "when RAG_API_TOKEN is set" do
      it "does not raise an error" do
        expect { described_class.new }.not_to raise_error
      end
    end
  end

  describe "#query" do
    context "with successful response" do
      before do
        stub_request(:post, "#{base_url}/query")
          .with(
            body: {
              question: question,
              sources: false,
              stream: false,
              top_k: 1
            }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Authorization" => "Bearer test_token_123"
            }
          )
          .to_return(
            status: 200,
            body: { answer: "Paris is the capital of France." }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the parsed response" do
        result = client.query(question)
        expect(result).to eq({ "answer" => "Paris is the capital of France." })
      end

      it "sends correct parameters" do
        stub_request(:post, "#{base_url}/query")
          .with(
            body: {
              question: question,
              sources: true,
              stream: false,
              top_k: 5
            }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Authorization" => "Bearer test_token_123"
            }
          )
          .to_return(
            status: 200,
            body: { answer: "Paris" }.to_json
          )

        client.query(question, sources: true, top_k: 5)

        expect(WebMock).to have_requested(:post, "#{base_url}/query")
          .with(body: hash_including({
            "question" => question,
            "sources" => true,
            "top_k" => 5
          }))
      end
    end

    context "when response is invalid JSON" do
      before do
        stub_request(:post, "#{base_url}/query")
          .to_return(status: 200, body: "invalid json")
      end

      it "raises InvalidResponseError" do
        expect { client.query(question) }.to raise_error(
          Rag::Client::InvalidResponseError,
          "Unable to parse response from RAG service"
        )
      end
    end

    context "when response does not contain answer field" do
      before do
        stub_request(:post, "#{base_url}/query")
          .to_return(
            status: 200,
            body: { result: "something else" }.to_json
          )
      end

      it "raises InvalidResponseError" do
        expect { client.query(question) }.to raise_error(
          Rag::Client::InvalidResponseError,
          "Received invalid response format from RAG service"
        )
      end
    end

    context "when authentication fails" do
      before do
        stub_request(:post, "#{base_url}/query")
          .to_return(status: 401)
      end

      it "raises AuthenticationError" do
        expect { client.query(question) }.to raise_error(
          Rag::Client::AuthenticationError,
          "RAG service authentication failed"
        )
      end
    end

    context "when bad request" do
      before do
        stub_request(:post, "#{base_url}/query")
          .to_return(status: 400)
      end

      it "raises InvalidResponseError" do
        expect { client.query(question) }.to raise_error(
          Rag::Client::InvalidResponseError,
          "Invalid request sent to RAG service"
        )
      end
    end

    context "when server error" do
      before do
        stub_request(:post, "#{base_url}/query")
          .to_return(status: 500)
      end

      it "raises Error" do
        expect { client.query(question) }.to raise_error(
          Rag::Client::Error,
          "RAG service is experiencing issues"
        )
      end
    end

    context "when connection error" do
      before do
        stub_request(:post, "#{base_url}/query")
          .to_raise(HTTParty::Error.new("Connection failed"))
      end

      it "raises ConnectionError" do
        expect { client.query(question) }.to raise_error(
          Rag::Client::ConnectionError,
          "Unable to reach RAG service"
        )
      end
    end

    context "when timeout" do
      before do
        stub_request(:post, "#{base_url}/query")
          .to_raise(Net::ReadTimeout)
      end

      it "raises TimeoutError" do
        expect { client.query(question) }.to raise_error(
          Rag::Client::TimeoutError,
          "Request timed out, please try again"
        )
      end
    end
  end
end
