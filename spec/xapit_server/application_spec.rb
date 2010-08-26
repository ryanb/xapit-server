require "spec_helper"

describe XapitServer::Application do
  before(:each) do
    # Start with a fresh database each time, use fixture to improve performance of tests
    fixture_path = File.expand_path("../../fixtures/blankdb", __FILE__)
    database_path = File.expand_path("../../../tmp/testdb", __FILE__)
    FileUtils.rm_rf(database_path)
    FileUtils.cp_r(fixture_path, database_path)
    @app = XapitServer::Application.new(:database_path => database_path)
    @request = Rack::MockRequest.new(@app)
  end
  
  it "should add a document to the database" do
    @request.post("/documents", :params => {:id => "foo"})
    @app.database.doccount.should == 1
  end
  
  it "should add a document to the database and remove it" do
    @request.post("/documents", :params => {:id => "foo"})
    @request.delete("/documents/foo")
    @app.database.doccount.should == 0
  end
end