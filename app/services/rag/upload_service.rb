module Rag
  class UploadService
    attr_reader :response, :error

    def initialize(file:, auto_index: false)
      @client = Client.new
      @file = file
      @auto_index = auto_index
      @response = nil
      @error = nil
    end

    def call
      begin
        @response = @client.upload_document(@file, auto_index: @auto_index)
        true
      rescue Client::Error => e
        @error = user_friendly_error(e)
        log_error(e)
        false
      end
    end

    def success?
      @error.nil? && @response.is_a?(Hash)
    end

    def file_name
      @response&.dig("file_name")
    end

    def file_size
      @response&.dig("file_size")
    end

    def indexed?
      @response&.dig("indexed") || false
    end

    def note
      @response&.dig("note")
    end

    private

    def user_friendly_error(exception)
      case exception
      when Client::ConnectionError
        "Unable to reach the upload service. Please try again later."
      when Client::TimeoutError
        "The upload took too long. Please try again with a smaller file."
      when Client::AuthenticationError
        "Service authentication failed. Please contact support."
      when Client::InvalidResponseError
        exception.message # This includes parsed validation errors from 422 responses
      else
        "An error occurred while uploading the document. Please try again."
      end
    end

    def log_error(exception)
      Rails.logger.error(
        "RAG Upload Error: " \
        "#{exception.class} - #{exception.message}"
      )
    end
  end
end
