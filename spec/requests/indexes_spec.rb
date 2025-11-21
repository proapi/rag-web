require "rails_helper"
require "webmock/rspec"

RSpec.describe "Indexes", type: :request do
  let(:user) { create(:user) }
  let(:base_url) { "http://localhost:3001" }
  let(:token) { "test_token_123" }

  before do
    stub_const("ENV", ENV.to_hash.merge(
      "RAG_API_URL" => base_url,
      "RAG_API_TOKEN" => token
    ))
  end

  describe "GET /indexes" do
    context "when authenticated" do
      before do
        sign_in(user)
      end

      context "with successful response containing indexes" do
        let(:indexes_response) do
          {
            "total" => 2,
            "indexes" => [
              {
                "operation_id" => 1,
                "status" => "completed",
                "embedding_model" => "sentence-transformers/all-MiniLM-L6-v2",
                "storage_dir" => "/path/to/storage",
                "data_dir" => "/path/to/data",
                "chunk_size" => 1024,
                "chunk_overlap" => 200,
                "top_k" => 5,
                "force_rebuild" => false,
                "triggered_by" => "cli",
                "num_documents" => 12,
                "duration_seconds" => 5.2,
                "error_message" => nil,
                "scheduled_at" => "2025-11-20T21:06:48.288280",
                "started_at" => "2025-11-20T21:06:48.288280",
                "completed_at" => "2025-11-20T21:06:49.631850",
                "metadata" => nil,
                "storage" => {
                  "docstore_size_bytes" => 37411,
                  "vector_store_size_bytes" => 108532,
                  "index_store_size_bytes" => 1255,
                  "last_indexed_at" => "2025-11-19T21:32:13.847581",
                  "last_indexed_at_local" => "2025-11-19T22:32:13.847585",
                  "current_status" => "completed",
                  "status_message" => "Indexing completed successfully (12 documents)",
                  "status_updated_at" => "2025-11-20T22:06:49.633937"
                }
              },
              {
                "operation_id" => 2,
                "status" => "pending",
                "embedding_model" => "sentence-transformers/all-MiniLM-L6-v2",
                "storage_dir" => "/path/to/storage",
                "data_dir" => "/path/to/data",
                "chunk_size" => 512,
                "chunk_overlap" => 100,
                "top_k" => 3,
                "force_rebuild" => true,
                "triggered_by" => "api",
                "num_documents" => 0,
                "duration_seconds" => 0,
                "error_message" => nil,
                "scheduled_at" => "2025-11-21T10:00:00.000000",
                "started_at" => nil,
                "completed_at" => nil,
                "metadata" => { "user_id" => 123 },
                "storage" => nil
              }
            ]
          }
        end

        before do
          stub_request(:get, "#{base_url}/indexes")
            .with(
              headers: {
                "Content-Type" => "application/json",
                "Authorization" => "Bearer #{token}"
              }
            )
            .to_return(
              status: 200,
              body: indexes_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "returns success" do
          get indexes_path
          expect(response).to have_http_status(:success)
        end

        it "displays index operation IDs" do
          get indexes_path
          expect(response.body).to include("Operation #1")
          expect(response.body).to include("Operation #2")
        end

        it "displays status badges" do
          get indexes_path
          expect(response.body).to include("Completed")
          expect(response.body).to include("Pending")
        end

        it "displays document counts" do
          get indexes_path
          expect(response.body).to include("12")
        end

        it "displays embedding models" do
          get indexes_path
          expect(response.body).to include("sentence-transformers/all-MiniLM-L6-v2")
        end

        it "displays storage information" do
          get indexes_path
          expect(response.body).to include("Docstore Size")
          expect(response.body).to include("Vector Store Size")
        end

        it "displays the total count" do
          get indexes_path
          expect(response.body).to include("2")
          expect(response.body).to match(/indexes\s+found/i)
        end
      end

      context "with successful response but no indexes" do
        let(:empty_response) do
          {
            "total" => 0,
            "indexes" => []
          }
        end

        before do
          stub_request(:get, "#{base_url}/indexes")
            .to_return(
              status: 200,
              body: empty_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "returns success" do
          get indexes_path
          expect(response).to have_http_status(:success)
        end

        it "displays empty state message" do
          get indexes_path
          expect(response.body).to include("No indexes found")
          expect(response.body).to include("There are currently no document indexes available")
        end
      end

      context "when authentication fails (401)" do
        before do
          stub_request(:get, "#{base_url}/indexes")
            .to_return(status: 401)
        end

        it "returns success but shows error message" do
          get indexes_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get indexes_path
          expect(flash[:alert]).to eq("Service authentication failed. Please contact support.")
        end

        it "displays error in response body" do
          get indexes_path
          expect(response.body).to include("Service authentication failed")
        end
      end

      context "when connection fails" do
        before do
          stub_request(:get, "#{base_url}/indexes")
            .to_raise(HTTParty::Error.new("Connection failed"))
        end

        it "returns success but shows error message" do
          get indexes_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get indexes_path
          expect(flash[:alert]).to eq("Unable to reach the indexing service. Please try again later.")
        end
      end

      context "when request times out" do
        before do
          stub_request(:get, "#{base_url}/indexes")
            .to_raise(Net::ReadTimeout)
        end

        it "returns success but shows error message" do
          get indexes_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get indexes_path
          expect(flash[:alert]).to eq("The request took too long. Please try again.")
        end
      end

      context "when server error occurs (500)" do
        before do
          stub_request(:get, "#{base_url}/indexes")
            .to_return(status: 500)
        end

        it "returns success but shows error message" do
          get indexes_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get indexes_path
          expect(flash[:alert]).to eq("An error occurred while fetching indexes. Please try again.")
        end
      end

      context "when response is invalid JSON" do
        before do
          stub_request(:get, "#{base_url}/indexes")
            .to_return(status: 200, body: "invalid json")
        end

        it "returns success but shows error message" do
          get indexes_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get indexes_path
          expect(flash[:alert]).to eq("Received an invalid response. Please try again.")
        end
      end

      context "when response does not contain indexes field" do
        before do
          stub_request(:get, "#{base_url}/indexes")
            .to_return(
              status: 200,
              body: { result: "something else" }.to_json
            )
        end

        it "returns success but shows error message" do
          get indexes_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get indexes_path
          expect(flash[:alert]).to eq("Received an invalid response. Please try again.")
        end
      end
    end

    context "when not authenticated" do
      # No sign_in call - this context tests unauthenticated behavior

      before do
        stub_request(:get, "#{base_url}/indexes")
          .to_return(
            status: 200,
            body: { total: 1, indexes: [] }.to_json
          )
      end

      it "redirects to login" do
        get indexes_path
        expect(response).to redirect_to(new_session_path)
      end

      it "does not make request to RAG service" do
        get indexes_path
        expect(WebMock).not_to have_requested(:get, "#{base_url}/indexes")
      end
    end
  end
end
