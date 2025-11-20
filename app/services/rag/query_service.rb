module Rag
  class QueryService
    attr_reader :user, :question, :query_record, :error

    def initialize(user:, question:)
      @user = user
      @question = question
      @client = Client.new
      @query_record = nil
      @error = nil
    end

    def call
      return false if question.blank?

      begin
        response = @client.query(question)

        @query_record = user.queries.create!(
          question: question,
          answer: response["answer"],
          metadata: response.except("answer")
        )

        true
      rescue Client::Error => e
        @error = user_friendly_error(e)
        log_error(e)

        @query_record = user.queries.create(
          question: question,
          error: e.message
        )

        false
      end
    end

    def success?
      @query_record&.successful? || false
    end

    def answer
      @query_record&.answer
    end

    private

    def user_friendly_error(exception)
      case exception
      when Client::ConnectionError
        "Unable to reach the AI service. Please try again later."
      when Client::TimeoutError
        "The request took too long. Please try again."
      when Client::AuthenticationError
        "Service authentication failed. Please contact support."
      when Client::InvalidResponseError
        "Received an invalid response. Please try again."
      else
        "An error occurred while processing your query. Please try again."
      end
    end

    def log_error(exception)
      Rails.logger.error(
        "RAG Query Error for User #{user.id}: " \
        "#{exception.class} - #{exception.message}\n" \
        "Question: #{question}"
      )
    end
  end
end
