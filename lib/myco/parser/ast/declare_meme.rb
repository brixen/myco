
module CodeTools::AST
  
  module ProcessorMethods
    def process_meme line, name, decorations, arguments, body
      DeclareMeme.new line, name, decorations, arguments, body
    end
  end
  
  class DeclareMemeBody < Iter
    attr_accessor :name
    
    def bytecode(g)
      pos(g)
      
      state = g.state
      state.scope.nest_scope self
      
      meth = new_generator g, @name, @arguments
      
      meth.push_state self
      meth.definition_line @line
      
      meth.state.push_name meth.name
      
      pos(meth)
      
      @arguments.bytecode meth
      
      @body.bytecode meth
      
      meth.ret
      meth.close
      
      meth.local_count = local_count
      meth.local_names = local_names
      meth.splat_index = @arguments.splat_index
      
      meth.pop_state
      
      g.push_scope
      g.send :for_method_definition, 0
      g.add_scope
      
      g.create_block meth
    end
  end
  
  class DeclareMeme < Node
    attr_accessor :name, :decorations, :arguments, :body
    
    def initialize line, name, decorations, arguments, body
      @line        = line
      @name        = name.value
      @decorations = decorations || ArrayLiteral.new(line, [])
      @arguments   = arguments || Parameters.new(line, [], nil, false, nil, nil, nil, nil)
      @body        = body || NilLiteral.new(line)
    end
    
    def to_sexp
      [:meme, @name, @decorations.to_sexp, @arguments.to_sexp, @body.to_sexp]
    end
    
    def bytecode(g)
      pos(g)
      
      meme_body = DeclareMemeBody.new(@line, @arguments, @body)
      meme_body.name = @name
      
      ##
      # module = scope.for_method_definition
      # module.send :declare_meme, @name, @decorations,
      #   CompiledCode(@body), const_scope, var_scope
      #
      g.push_scope
      g.send :for_method_definition, 0
        g.push_literal @name
        @decorations.bytecode g
        meme_body.bytecode(g)
        g.push_scope
        g.push_variables
      g.send :declare_meme, 5
    end
  end
  
end
