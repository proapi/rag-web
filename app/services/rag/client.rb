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

      handle_response(response)
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

    private

    def headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@token}"
      }
    end

    def handle_response(response)
      case response.code
      when 200
        parse_success_response(response)
      when 401, 403
        Rails.logger.error("RAG API Authentication Failed: #{response.code}")
        raise AuthenticationError, "RAG service authentication failed"
      when 400
        Rails.logger.error("RAG API Bad Request: #{response.body}")
        raise InvalidResponseError, "Invalid request sent to RAG service"
      when 500..599
        Rails.logger.error("RAG API Server Error: #{response.code} - #{response.body}")
        raise Error, "RAG service is experiencing issues"
      else
        Rails.logger.error("RAG API Unexpected Response: #{response.code}")
        raise Error, "Received unexpected response from RAG service"
      end
    end

    def parse_success_response(response)
      parsed = JSON.parse(response.body)

      unless parsed.is_a?(Hash) && parsed["answer"]
        Rails.logger.error("RAG API Invalid Response Format: #{response.body}")
        raise InvalidResponseError, "Received invalid response format from RAG service"
      end

      parsed
    rescue JSON::ParserError => e
      Rails.logger.error("RAG API JSON Parse Error: #{e.message}")
      raise InvalidResponseError, "Unable to parse response from RAG service"
    end
  end
end
