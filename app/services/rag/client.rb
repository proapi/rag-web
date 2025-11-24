module Rag
  class Client
    include HTTParty

    class Error < StandardError; end
    class ConnectionError < Error; end
    class AuthenticationError < Error; end
    class TimeoutError < Error; end
    class InvalidResponseError < Error; end

    base_uri ENV.fetch("RAG_API_URL", "http://localhost:3001")
    default_timeout 30

    def initialize
      @token = ENV.fetch("RAG_API_TOKEN", nil)
      raise AuthenticationError, "RAG_API_TOKEN is not configured" if @token.nil?
    end

    def query(question, sources: false, stream: false, top_k: 1)
      response = self.class.post(
        "/query",
        headers: headers,
        body: {
          question: question,
          sources: sources,
          stream: stream,
          top_k: top_k
        }.to_json,
        timeout: 30
      )

      handle_response(response, :query)
    rescue AuthenticationError, InvalidResponseError, Error
      # Re-raise our custom errors
      raise
    rescue HTTParty::Error => e
      Rails.logger.error("RAG API HTTParty Error: #{e.message}")
      raise ConnectionError, "Unable to reach RAG service"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("RAG API Timeout: #{e.message}")
      raise TimeoutError, "Request timed out, please try again"
    rescue StandardError => e
      Rails.logger.error("RAG API Unknown Error: #{e.class} - #{e.message}")
      raise Error, "An unexpected error occurred"
    end

    def list_indexes
      response = self.class.get(
        "/indexes",
        headers: headers,
        timeout: 30
      )

      handle_response(response, :indexes)
    rescue AuthenticationError, InvalidResponseError, Error
      # Re-raise our custom errors
      raise
    rescue HTTParty::Error => e
      Rails.logger.error("RAG API HTTParty Error: #{e.message}")
      raise ConnectionError, "Unable to reach RAG service"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("RAG API Timeout: #{e.message}")
      raise TimeoutError, "Request timed out, please try again"
    rescue StandardError => e
      Rails.logger.error("RAG API Unknown Error: #{e.class} - #{e.message}")
      raise Error, "An unexpected error occurred"
    end

    def list_documents
      response = self.class.get(
        "/documents",
        headers: headers,
        timeout: 30
      )

      handle_response(response, :documents)
    rescue AuthenticationError, InvalidResponseError, Error
      # Re-raise our custom errors
      raise
    rescue HTTParty::Error => e
      Rails.logger.error("RAG API HTTParty Error: #{e.message}")
      raise ConnectionError, "Unable to reach RAG service"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("RAG API Timeout: #{e.message}")
      raise TimeoutError, "Request timed out, please try again"
    rescue StandardError => e
      Rails.logger.error("RAG API Unknown Error: #{e.class} - #{e.message}")
      raise Error, "An unexpected error occurred"
    end

    def upload_document(file, auto_index: false)
      response = self.class.post(
        "/documents/upload",
        headers: upload_headers,
        body: {
          file: file,
          auto_index: auto_index
        },
        timeout: 60 # Longer timeout for file uploads
      )

      handle_response(response, :upload)
    rescue AuthenticationError, InvalidResponseError, Error
      # Re-raise our custom errors
      raise
    rescue HTTParty::Error => e
      Rails.logger.error("RAG API HTTParty Error: #{e.message}")
      raise ConnectionError, "Unable to reach RAG service"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("RAG API Timeout: #{e.message}")
      raise TimeoutError, "Upload timed out, please try again"
    rescue StandardError => e
      Rails.logger.error("RAG API Unknown Error: #{e.class} - #{e.message}")
      raise Error, "An unexpected error occurred during upload"
    end

    def build_index(force: true)
      response = self.class.post(
        "/index/build",
        headers: headers,
        body: {
          force: force
        }.to_json,
        timeout: 60 # Longer timeout for index building
      )

      handle_response(response, :build_index)
    rescue AuthenticationError, InvalidResponseError, Error
      # Re-raise our custom errors
      raise
    rescue HTTParty::Error => e
      Rails.logger.error("RAG API HTTParty Error: #{e.message}")
      raise ConnectionError, "Unable to reach RAG service"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("RAG API Timeout: #{e.message}")
      raise TimeoutError, "Index build timed out, please try again"
    rescue StandardError => e
      Rails.logger.error("RAG API Unknown Error: #{e.class} - #{e.message}")
      raise Error, "An unexpected error occurred during index build"
    end

    private

    def headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@token}"
      }
    end

    def upload_headers
      {
        "Authorization" => "Bearer #{@token}"
        # HTTParty will automatically set Content-Type for multipart/form-data
      }
    end

    def handle_response(response, type)
      case response.code
      when 200
        parse_success_response(response, type)
      when 401, 403
        Rails.logger.error("RAG API Authentication Failed: #{response.code}")
        raise AuthenticationError, "RAG service authentication failed"
      when 400
        Rails.logger.error("RAG API Bad Request: #{response.body}")
        raise InvalidResponseError, "Invalid request sent to RAG service"
      when 422
        Rails.logger.error("RAG API Validation Error: #{response.body}")
        raise InvalidResponseError, parse_validation_errors(response)
      when 500..599
        Rails.logger.error("RAG API Server Error: #{response.code} - #{response.body}")
        raise Error, "RAG service is experiencing issues"
      else
        Rails.logger.error("RAG API Unexpected Response: #{response.code}")
        raise Error, "Received unexpected response from RAG service"
      end
    end

    def parse_success_response(response, type)
      parsed = JSON.parse(response.body)

      case type
      when :query
        unless parsed.is_a?(Hash) && parsed["answer"]
          Rails.logger.error("RAG API Invalid Response Format: #{response.body}")
          raise InvalidResponseError, "Received invalid response format from RAG service"
        end
      when :indexes
        unless parsed.is_a?(Hash) && parsed.key?("indexes")
          Rails.logger.error("RAG API Invalid Indexes Response Format: #{response.body}")
          raise InvalidResponseError, "Received invalid indexes response format from RAG service"
        end
      when :documents
        unless parsed.is_a?(Array)
          Rails.logger.error("RAG API Invalid Documents Response Format: #{response.body}")
          raise InvalidResponseError, "Received invalid documents response format from RAG service"
        end
      when :upload
        unless parsed.is_a?(Hash) && parsed["status"]
          Rails.logger.error("RAG API Invalid Upload Response Format: #{response.body}")
          raise InvalidResponseError, "Received invalid upload response format from RAG service"
        end
      when :build_index
        unless parsed.is_a?(Hash)
          Rails.logger.error("RAG API Invalid Build Index Response Format: #{response.body}")
          raise InvalidResponseError, "Received invalid build index response format from RAG service"
        end
      end

      parsed
    rescue JSON::ParserError => e
      Rails.logger.error("RAG API JSON Parse Error: #{e.message}")
      raise InvalidResponseError, "Unable to parse response from RAG service"
    end

    def parse_validation_errors(response)
      parsed = JSON.parse(response.body)
      if parsed.is_a?(Hash) && parsed["detail"].is_a?(Array)
        errors = parsed["detail"].map { |err| err["msg"] }.join(", ")
        "Validation error: #{errors}"
      else
        "Validation error occurred"
      end
    rescue JSON::ParserError
      "Validation error occurred"
    end
  end
end
