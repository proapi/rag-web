class DocumentsController < ApplicationController
  def index
    service = Rag::DocumentsService.new

    if service.call
      @documents = service.documents
      @total_documents = @documents.length
    else
      flash.now[:alert] = service.error
      @documents = []
      @total_documents = 0
    end
  end
end
