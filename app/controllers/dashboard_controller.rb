class DashboardController < ApplicationController
  def show
    @recent_queries = Current.user.queries.recent.limit(10)
    @documents_count = fetch_documents_count
  end

  def query
    service = Rag::QueryService.new(user: Current.user, question: params[:question])

    if service.call
      @query = service.query_record
      respond_to do |format|
        format.turbo_stream
      end
    else
      @error = service.error
      @question = params[:question]
      respond_to do |format|
        format.turbo_stream { render :error, status: :unprocessable_content }
      end
    end
  end

  def documents_stat
    @documents_count = fetch_documents_count
    render layout: false
  end

  private

  def fetch_documents_count
    service = Rag::DocumentsService.new
    service.call ? service.documents.length : 0
  end
end
