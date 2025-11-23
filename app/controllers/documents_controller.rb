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

  def new
    # Renders the upload form modal
  end

  def create
    file = params[:file]
    auto_index = params[:auto_index] == "1"

    if file.blank?
      flash.now[:alert] = "Please select a file to upload"
      render :new, status: :unprocessable_entity
      return
    end

    service = Rag::UploadService.new(file: file, auto_index: auto_index)

    if service.call
      # Fetch the uploaded document details to add to the list
      @uploaded_document = {
        "file_name" => service.file_name,
        "file_type" => File.extname(service.file_name).delete(".").upcase,
        "file_size" => service.file_size,
        "doc_id" => service.response["doc_id"] || "pending",
        "file_path" => service.response["file_path"] || ""
      }

      flash.now[:notice] = build_success_message(service)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to documents_path, notice: build_success_message(service) }
      end
    else
      flash.now[:alert] = service.error

      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def build_success_message(service)
    message = "File '#{service.file_name}' uploaded successfully"
    message += " (#{format_file_size(service.file_size)})"
    message += service.indexed? ? ". Document has been indexed." : ". Document will be indexed later."
    message += " #{service.note}" if service.note.present?
    message
  end

  def format_file_size(size)
    return "0 B" if size.nil? || size.zero?

    units = [ "B", "KB", "MB", "GB" ]
    exp = (Math.log(size) / Math.log(1024)).to_i
    exp = [ exp, units.length - 1 ].min

    "%.1f %s" % [ size.to_f / 1024**exp, units[exp] ]
  end
end
