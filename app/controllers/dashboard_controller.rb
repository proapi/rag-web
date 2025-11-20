class DashboardController < ApplicationController
  def show
    @recent_queries = Current.user.queries.recent.limit(10)
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
end
