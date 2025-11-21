class DocumentsController < ApplicationController
  def index
    service = Rag::DocumentsService.new

    if service.call
      @documents = service.documents
      @documents_by_file = @documents.group_by { |doc| doc["file_name"] }
      @total_documents = @documents.length
      @total_files = @documents_by_file.keys.length
    else
      flash.now[:alert] = service.error
      @documents = []
      @documents_by_file = {}
      @total_documents = 0
      @total_files = 0
    end
  end
end
