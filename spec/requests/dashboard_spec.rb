require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }

  describe "GET /dashboard/show" do
    before do
      sign_in(user)
    end
    it "returns success" do
      get dashboard_show_path
      expect(response).to have_http_status(:success)
    end

    it "displays recent queries" do
      query1 = create(:query, user: user, question: "Question 1")
      query2 = create(:query, user: user, question: "Question 2")

      get dashboard_show_path

      expect(response.body).to include("Question 1")
      expect(response.body).to include("Question 2")
    end

    it "shows the query count" do
      create_list(:query, 5, user: user)

      get dashboard_show_path

      expect(response.body).to include("5")
    end
  end

  describe "POST /dashboard/query" do
    let(:question) { "What is the capital of France?" }
    let(:client_double) { instance_double(Rag::Client) }
    let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" } }

    before do
      allow(Rag::Client).to receive(:new).and_return(client_double)
    end

    context "with successful query" do
      before do
        sign_in(user)
        allow(client_double).to receive(:query)
          .and_return({ "answer" => "Paris is the capital of France." })
      end

      it "returns success" do
        post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        expect(response).to have_http_status(:success)
      end

      it "creates a query record" do
        expect {
          post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        }.to change(Query, :count).by(1)
      end

      it "returns turbo stream response" do
        post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes the answer in the response" do
        post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        expect(response.body).to include("Paris is the capital of France.")
      end
    end

    context "with failed query" do
      before do
        sign_in(user)
        allow(client_double).to receive(:query)
          .and_raise(Rag::Client::ConnectionError, "Connection failed")
      end

      it "returns unprocessable entity status" do
        post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "creates a query record with error" do
        expect {
          post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        }.to change(Query, :count).by(1)

        query = Query.last
        expect(query.error).to eq("Connection failed")
      end

      it "returns turbo stream error response" do
        post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes error message in response" do
        post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        expect(response.body).to include("Unable to reach the AI service")
      end
    end

    context "with blank question" do
      before do
        sign_in(user)
      end

      it "does not create a query record" do
        expect {
          post dashboard_query_path, params: { question: "" }, headers: turbo_stream_headers
        }.not_to change(Query, :count)
      end

      it "returns unprocessable entity status" do
        post dashboard_query_path, params: { question: "" }, headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when not authenticated" do
      # No sign_in call - this context tests unauthenticated behavior

      it "redirects to login" do
        post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        expect(response).to redirect_to(new_session_path)
      end

      it "does not create a query record" do
        expect {
          post dashboard_query_path, params: { question: question }, headers: turbo_stream_headers
        }.not_to change(Query, :count)
      end
    end
  end
end
