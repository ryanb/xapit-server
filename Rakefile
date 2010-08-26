require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = Rake::FileList["spec/**/*_spec.rb"]
end

task :default => :spec
