module XapitServer
  class Application
    def initialize(options)
      @options = options
    end
    
    def database
      @database ||= Xapian::WritableDatabase.new(@options[:database_path], Xapian::DB_CREATE_OR_OPEN)
    end
    
    def call(env)
      request = Rack::Request.new(env)
      case "#{request.request_method} #{request.path}"
      when "POST /documents" then add_document(request.params)
      when %r{DELETE /documents/(.+)} then delete_document($1)
      else [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
      end
    end
    
    private
    
    def add_document(params)
      raise "id parameter should be passed when creating document" if params["id"].nil?
      document = Xapian::Document.new
      document.add_term("Q" + params["id"])
      database.add_document(document)
      [200, {"Content-Type" => "text/plain"}, [""]]
    end
    
    def delete_document(id)
      database.delete_document("Q" + id)
      [200, {"Content-Type" => "text/plain"}, [""]]
    end
  end
end
