module Rag
  class DocumentsService
    attr_reader :documents, :error

    def initialize
      @client = Client.new
      @documents = []
      @error = nil
    end

    def call
      begin
        response = @client.list_documents

        @documents = response.is_a?(Array) ? response : []

        true
      rescue Client::Error => e
        @error = user_friendly_error(e)
        log_error(e)
        false
      end
    end

    def success?
      @error.nil? && @documents.is_a?(Array)
    end

    private

    def user_friendly_error(exception)
      case exception
      when Client::ConnectionError
        "Unable to reach the document service. Please try again later."
      when Client::TimeoutError
        "The request took too long. Please try again."
      when Client::AuthenticationError
        "Service authentication failed. Please contact support."
      when Client::InvalidResponseError
        "Received an invalid response. Please try again."
      else
        "An error occurred while fetching documents. Please try again."
      end
    end

    def log_error(exception)
      Rails.logger.error(
        "RAG Documents Error: " \
        "#{exception.class} - #{exception.message}"
      )
    end
  end
end
