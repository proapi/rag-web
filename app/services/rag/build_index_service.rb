module Rag
  class BuildIndexService
    attr_reader :error

    def initialize
      @client = Client.new
      @error = nil
    end

    def call
      begin
        @client.build_index(force: true)
        true
      rescue Client::Error => e
        @error = user_friendly_error(e)
        log_error(e)
        false
      end
    end

    def success?
      @error.nil?
    end

    private

    def user_friendly_error(exception)
      case exception
      when Client::ConnectionError
        "Unable to reach the indexing service. Please try again later."
      when Client::TimeoutError
        "The index build request took too long. Please try again."
      when Client::AuthenticationError
        "Service authentication failed. Please contact support."
      when Client::InvalidResponseError
        "Received an invalid response. Please try again."
      else
        "An error occurred while triggering index build. Please try again."
      end
    end

    def log_error(exception)
      Rails.logger.error(
        "RAG Build Index Error: " \
        "#{exception.class} - #{exception.message}"
      )
    end
  end
end
