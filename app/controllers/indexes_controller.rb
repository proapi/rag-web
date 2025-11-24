class IndexesController < ApplicationController
  def index
    service = Rag::IndexesService.new

    if service.call
      @indexes = service.indexes
      @total = service.total
    else
      flash.now[:alert] = service.error unless turbo_frame_request?
      @indexes = []
      @total = 0
    end

    # When requested as a turbo-frame (from auto-refresh), render just the frame with list
    if turbo_frame_request?
      render partial: "indexes/frame_list", layout: false
    end
  end

  def build
    service = Rag::BuildIndexService.new

    if service.call
      flash.now[:notice] = "Index build triggered successfully"
    else
      flash.now[:alert] = service.error
    end

    # Fetch current indexes list for display (will be refreshed after delay)
    indexes_service = Rag::IndexesService.new
    if indexes_service.call
      @indexes = indexes_service.indexes
      @total = indexes_service.total
    else
      @indexes = []
      @total = 0
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to indexes_path }
    end
  end
end
