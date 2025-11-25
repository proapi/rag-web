require 'webmock/rspec'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # Stub the RAG API list_documents endpoint by default
    stub_request(:get, "#{ENV.fetch('RAG_API_URL', 'http://localhost:3001')}/documents")
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
