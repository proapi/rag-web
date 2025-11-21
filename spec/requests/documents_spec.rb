require "rails_helper"
require "webmock/rspec"

RSpec.describe "Documents", type: :request do
  let(:user) { create(:user) }
  let(:base_url) { "http://localhost:3001" }
  let(:token) { "test_token_123" }

  before do
    stub_const("ENV", ENV.to_hash.merge(
      "RAG_API_URL" => base_url,
      "RAG_API_TOKEN" => token
    ))
  end

  describe "GET /documents" do
    context "when authenticated" do
      before do
        sign_in(user)
      end

      context "with successful response containing documents" do
        let(:documents_response) do
          [
            {
              "doc_id" => "67a6b7ed-9474-403f-b577-681e86030a6d",
              "file_name" => "database_design_principles.pdf",
              "file_path" => "/Users/pawelski/Projects/AI/rag-system/rag-core/data/database_design_principles.pdf",
              "file_type" => ".pdf"
            },
            {
              "doc_id" => "047414f0-42e9-42bb-ba35-ec645239fdfe",
              "file_name" => "database_design_principles.pdf",
              "file_path" => "/Users/pawelski/Projects/AI/rag-system/rag-core/data/database_design_principles.pdf",
              "file_type" => ".pdf"
            },
            {
              "doc_id" => "4ec6a2a1-fe37-4267-8722-f2196a6775c8",
              "file_name" => "database_design_principles.pdf",
              "file_path" => "/Users/pawelski/Projects/AI/rag-system/rag-core/data/database_design_principles.pdf",
              "file_type" => ".pdf"
            },
            {
              "doc_id" => "a980a860-276b-46fa-a54a-8794154c7307",
              "file_name" => "git_workflow_guide.pdf",
              "file_path" => "/Users/pawelski/Projects/AI/rag-system/rag-core/data/git_workflow_guide.pdf",
              "file_type" => ".pdf"
            }
          ]
        end

        before do
          stub_request(:get, "#{base_url}/documents")
            .with(
              headers: {
                "Content-Type" => "application/json",
                "Authorization" => "Bearer #{token}"
              }
            )
            .to_return(
              status: 200,
              body: documents_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "returns success" do
          get documents_path
          expect(response).to have_http_status(:success)
        end

        it "displays document file names" do
          get documents_path
          expect(response.body).to include("database_design_principles.pdf")
          expect(response.body).to include("git_workflow_guide.pdf")
        end

        it "displays file type badges" do
          get documents_path
          expect(response.body).to include("PDF")
        end

        it "displays document IDs" do
          get documents_path
          expect(response.body).to include("67a6b7ed-9474-403f-b577-681e86030a6d")
          expect(response.body).to include("a980a860-276b-46fa-a54a-8794154c7307")
        end

        it "displays file paths" do
          get documents_path
          expect(response.body).to include("/Users/pawelski/Projects/AI/rag-system/rag-core/data/database_design_principles.pdf")
        end

        it "displays total document and file counts" do
          get documents_path
          expect(response.body).to include("4")
          expect(response.body).to match(/documents/i)
          expect(response.body).to include("2")
          expect(response.body).to match(/files/i)
        end

        it "groups documents by file name" do
          get documents_path
          # Should show 3 documents for database_design_principles.pdf
          expect(response.body).to include("3")
          expect(response.body).to match(/documents/i)
          # Should show 1 document for git_workflow_guide.pdf
          expect(response.body).to include("1")
          expect(response.body).to match(/document/i)
        end
      end

      context "with successful response but no documents" do
        let(:empty_response) { [] }

        before do
          stub_request(:get, "#{base_url}/documents")
            .to_return(
              status: 200,
              body: empty_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "returns success" do
          get documents_path
          expect(response).to have_http_status(:success)
        end

        it "displays empty state message" do
          get documents_path
          expect(response.body).to include("No documents found")
          expect(response.body).to include("Get started by uploading your first document")
        end

        it "displays upload prompt" do
          get documents_path
          expect(response.body).to include("Documents will appear here once they have been indexed")
        end
      end

      context "when authentication fails (401)" do
        before do
          stub_request(:get, "#{base_url}/documents")
            .to_return(status: 401)
        end

        it "returns success but shows error message" do
          get documents_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get documents_path
          expect(flash[:alert]).to eq("Service authentication failed. Please contact support.")
        end

        it "displays error in response body" do
          get documents_path
          expect(response.body).to include("Service authentication failed")
        end
      end

      context "when connection fails" do
        before do
          stub_request(:get, "#{base_url}/documents")
            .to_raise(HTTParty::Error.new("Connection failed"))
        end

        it "returns success but shows error message" do
          get documents_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get documents_path
          expect(flash[:alert]).to eq("Unable to reach the document service. Please try again later.")
        end
      end

      context "when request times out" do
        before do
          stub_request(:get, "#{base_url}/documents")
            .to_raise(Net::ReadTimeout)
        end

        it "returns success but shows error message" do
          get documents_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get documents_path
          expect(flash[:alert]).to eq("The request took too long. Please try again.")
        end
      end

      context "when server error occurs (500)" do
        before do
          stub_request(:get, "#{base_url}/documents")
            .to_return(status: 500)
        end

        it "returns success but shows error message" do
          get documents_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get documents_path
          expect(flash[:alert]).to eq("An error occurred while fetching documents. Please try again.")
        end
      end

      context "when response is invalid JSON" do
        before do
          stub_request(:get, "#{base_url}/documents")
            .to_return(status: 200, body: "invalid json")
        end

        it "returns success but shows error message" do
          get documents_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get documents_path
          expect(flash[:alert]).to eq("Received an invalid response. Please try again.")
        end
      end

      context "when response is not an array" do
        before do
          stub_request(:get, "#{base_url}/documents")
            .to_return(
              status: 200,
              body: { result: "something else" }.to_json
            )
        end

        it "returns success but shows error message" do
          get documents_path
          expect(response).to have_http_status(:success)
        end

        it "displays flash error message" do
          get documents_path
          expect(flash[:alert]).to eq("Received an invalid response. Please try again.")
        end
      end

      context "with single document" do
        let(:single_document_response) do
          [
            {
              "doc_id" => "67a6b7ed-9474-403f-b577-681e86030a6d",
              "file_name" => "single_file.txt",
              "file_path" => "/path/to/single_file.txt",
              "file_type" => ".txt"
            }
          ]
        end

        before do
          stub_request(:get, "#{base_url}/documents")
            .to_return(
              status: 200,
              body: single_document_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "uses singular form for counts" do
          get documents_path
          # Should show "1 document across 1 file"
          expect(response.body).to include("1")
          expect(response.body).to match(/document(?!s)/i) # matches "document" but not "documents"
          expect(response.body).to match(/file(?!s)/i) # matches "file" but not "files"
        end
      end

      context "with many documents for same file (more than 5)" do
        let(:many_documents_response) do
          (1..10).map do |i|
            {
              "doc_id" => "doc-id-#{i}",
              "file_name" => "large_document.pdf",
              "file_path" => "/path/to/large_document.pdf",
              "file_type" => ".pdf"
            }
          end
        end

        before do
          stub_request(:get, "#{base_url}/documents")
            .to_return(
              status: 200,
              body: many_documents_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "shows scrollable list with scroll hint" do
          get documents_path
          expect(response.body).to include("Scroll to view all document IDs")
        end

        it "displays all document IDs" do
          get documents_path
          (1..10).each do |i|
            expect(response.body).to include("doc-id-#{i}")
          end
        end
      end
    end

    context "when not authenticated" do
      # No sign_in call - this context tests unauthenticated behavior

      before do
        stub_request(:get, "#{base_url}/documents")
          .to_return(
            status: 200,
            body: [].to_json
          )
      end

      it "redirects to login" do
        get documents_path
        expect(response).to redirect_to(new_session_path)
      end

      it "does not make request to RAG service" do
        get documents_path
        expect(WebMock).not_to have_requested(:get, "#{base_url}/documents")
      end
    end
  end
end
