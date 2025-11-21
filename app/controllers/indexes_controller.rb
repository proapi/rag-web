class IndexesController < ApplicationController
  def index
    service = Rag::IndexesService.new

    if service.call
      @indexes = service.indexes
      @total = service.total
    else
      flash.now[:alert] = service.error
      @indexes = []
      @total = 0
    end
  end
end
