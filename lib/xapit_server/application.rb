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
      when %r{GET /documents/(.+)} then fetch_document($1)
      when %r{DELETE /documents/(.+)} then delete_document($1)
      when %r{PUT /documents/(.+)} then update_document($1, request.params)
      when %r{.+ /queries$} then query_documents(request.params)
      else [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
      end
    end
    
    private
    
    def add_document(params)
      document = generate_document(params)
      database.add_document(document)
      [200, {"Content-Type" => "text/plain"}, [""]]
    end
    
    def fetch_document(id)
      enquire = Xapian::Enquire.new(database)
      enquire.query = Xapian::Query.new("Q#{id}")
      id, data = enquire.mset(0, 500).matches.first.document.data.split("|DATA|")
      [200, {"Content-Type" => "text/plain"}, [data]]
    end
    
    def delete_document(id)
      database.delete_document("Q" + id)
      [200, {"Content-Type" => "text/plain"}, [""]]
    end
    
    def update_document(id, params)
      document = generate_document({"id" => id}.merge(params))
      database.replace_document("Q#{id}", document)
      [200, {"Content-Type" => "text/plain"}, [""]]
    end
    
    def query_documents(params)
      enquire = Xapian::Enquire.new(database)
      enquire.query = Xapian::Query.unserialise(params["query"])
      docs = enquire.mset(0, 500).matches.map do |match|
        match.document.data.split("|DATA|").first
      end
      [200, {"Content-Type" => "text/plain"}, [docs.join(",")]]
    end
    
    def generate_document(params)
      raise "id parameter should be passed when creating document" if params["id"].nil?
      document = Xapian::Document.new
      document.data = "#{params['id']}|DATA|#{params['data']}"
      document.add_term("Q#{params['id']}")
      (params["terms"] || "").split(",").each do |term|
        document.add_term(term)
      end
      document
    end
  end
end
