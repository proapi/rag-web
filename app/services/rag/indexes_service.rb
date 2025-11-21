module Rag
  class IndexesService
    attr_reader :indexes, :total, :error

    def initialize
      @client = Client.new
      @indexes = []
      @total = 0
      @error = nil
    end

    def call
      begin
        response = @client.list_indexes

        @indexes = response["indexes"] || []
        @total = response["total"] || @indexes.length

        true
      rescue Client::Error => e
        @error = user_friendly_error(e)
        log_error(e)
        false
      end
    end

    def success?
      @error.nil? && @indexes.is_a?(Array)
    end

    private

    def user_friendly_error(exception)
      case exception
      when Client::ConnectionError
        "Unable to reach the indexing service. Please try again later."
      when Client::TimeoutError
        "The request took too long. Please try again."
      when Client::AuthenticationError
        "Service authentication failed. Please contact support."
      when Client::InvalidResponseError
        "Received an invalid response. Please try again."
      else
        "An error occurred while fetching indexes. Please try again."
      end
    end

    def log_error(exception)
      Rails.logger.error(
        "RAG Indexes Error: " \
        "#{exception.class} - #{exception.message}"
      )
    end
  end
end
