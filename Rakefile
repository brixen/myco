
require 'rspec/core/rake_task'


task :default => :sandbox


file 'lib/myco/parser/lexer.rb' => 'lib/myco/parser/lexer.rl' do
  puts "Building Lexer..."
  raise "Ragel failed to build Lexer..." unless \
    system "ragel -R lib/myco/parser/lexer_skeleton.rl" \
                " -o lib/myco/parser/lexer.rb"
end

file 'lib/myco/parser/builder.rb' => 'lib/myco/parser/builder.racc' do
  puts "Building Builder..."
  print "\033[1;31m" # Use bold red text color in terminal for Racc warnings
  
  raise "Racc failed to build Builder..." unless \
    system "racc -t lib/myco/parser/builder.racc -v" \
               " -o lib/myco/parser/builder.rb"
  
  print "\033[0m" # End terminal coloring
end


task :build_lexer => 'lib/myco/parser/lexer.rb'
task :build_builder => 'lib/myco/parser/builder.rb'
task :build => [:build_lexer, :build_builder]


RSpec::Core::RakeTask.new :test => :build

task :sandbox => :build do
  require_relative 'sandbox.rb'
end
