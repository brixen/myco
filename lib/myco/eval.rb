
module Myco
  
  # Most of method is stolen from Rubinius implementation of Kernel#eval
  def self.eval(string, scope=nil, filename=nil, lineno=nil, type=:myco)
    string = StringValue(string)
    filename = StringValue(filename) if filename
    lineno = Rubinius::Type.coerce_to lineno, Fixnum, :to_i if lineno
    lineno = 1 if filename && !lineno
    
    binding = ::Binding.setup(Rubinius::VariableScope.of_sender,
                              Rubinius::CompiledCode.of_sender,
                              (scope||Rubinius::ConstantScope.of_sender),
                              self)
    
    filename ||= "(eval)"
    
    lineno ||= binding.line_number
    
    existing_scope = binding.constant_scope
    binding.constant_scope = existing_scope.dup
    
    compiler_class = case type
    when :myco; Myco::ToolSet::Compiler
    when :ruby; Rubinius::ToolSets::Runtime::Compiler
    else; raise NotImplementedError
    end
    
    be = compiler_class.construct_block string, binding, filename, lineno
    
    result = be.call_on_instance(binding.self)
    binding.constant_scope = existing_scope
    result
  end
  
  def self.resolve_file path, load_paths=[]
    tmp_path = File.expand_path(path)
    use_path = File.file?(tmp_path) && tmp_path
    load_paths.each do |load_path|
      break if use_path
      tmp_path = File.expand_path(path, load_path)
      use_path = File.file?(tmp_path) && tmp_path
    end
    
    raise ArgumentError, "Couldn't resolve file: #{path.inspect} \n" \
                         "in load_paths: #{load_paths.inspect}" \
      unless use_path
    
    use_path
  end
  
  # TODO: deprecate with proper import set of functions
  def self.eval_file path, load_paths=nil, get_last=true, scope=nil
    load_paths ||= [File.dirname(Rubinius::VM.backtrace(1).first.file)]
    use_path = resolve_file path, load_paths
    file_toplevel = Myco.eval File.read(use_path), scope, use_path, 1
    get_last ? file_toplevel.component.__last__ : file_toplevel.component
  end
  
  def self.file_to_ruby path, load_paths=nil
    load_paths ||= [File.dirname(Rubinius::VM.backtrace(1).first.file)]
    use_path = resolve_file path, load_paths
    parser = Myco::ToolSet::Parser.new(use_path, 1, [])
    ast = parser.parse_string File.read(use_path)
    ast.to_ruby_code
  end
  
  # Override eval_file to go through AST::Node#to_ruby first
  # TODO: Make this override conditional to only do when bootstrapping
  def self.eval_file path, load_paths=nil, get_last=true, scope=nil
    load_paths ||= [File.dirname(Rubinius::VM.backtrace(1).first.file)]
    use_path = resolve_file path, load_paths
    ruby_code = file_to_ruby(path, load_paths)
    
    # Write the ruby code to a temporary file for viewing/debugging
    use_path = "#{use_path}.rb"
    tmp_path = File.join("/tmp/myco_to_ruby", use_path)
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(tmp_path))
    File.open(tmp_path, "w+") { |file| file.write(ruby_code) }
    
    file_toplevel = Myco.eval(ruby_code, scope, use_path, 1, :ruby)
    get_last ? file_toplevel.component.__last__ : file_toplevel.component
  end if ENV['MYCO_TO_RUBY']
  
  def self.rescue
    begin
      yield
    rescue Exception=>e
      unless e.is_a? SystemExit
        puts e.awesome_backtrace.show
        puts e.awesome_backtrace.first_color + e.message + "\033[0m"
        puts
        exit(1)
      end
    end
  end
end
