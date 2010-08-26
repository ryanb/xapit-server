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
      when %r{.+ /queries$} then query_documents(request.params)
      else [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
      end
    end
    
    private
    
    def add_document(params)
      raise "id parameter should be passed when creating document" if params["id"].nil?
      document = Xapian::Document.new
      document.data = params["id"]
      document.add_term("Q" + params["id"])
      (params["terms"] || "").split(",").each do |term|
        document.add_term(term)
      end
      database.add_document(document)
      [200, {"Content-Type" => "text/plain"}, [""]]
    end
    
    def delete_document(id)
      database.delete_document("Q" + id)
      [200, {"Content-Type" => "text/plain"}, [""]]
    end
    
    def query_documents(params)
      enquire = Xapian::Enquire.new(database)
      enquire.query = Xapian::Query.unserialise(params["query"])
      docs = enquire.mset(0, 500).matches.map do |match|
        match.document.data
      end
      [200, {"Content-Type" => "text/plain"}, [docs.join(",")]]
    end
  end
end
