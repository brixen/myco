
require_relative 'myco_module_scope'


module CodeTools::AST
  
  module BuilderMethods
    def category loc, name, body
      DeclareCategory.new loc.line, name, body
    end
  end
  
  class DeclareCategoryScope < MycoModuleScope
    def body_bytecode g
      g.push_scope
      g.send :set_myco_category, 0
      g.pop
      
      @body.bytecode g
    end
  end
  
  class DeclareCategory < Node
    attr_accessor :name, :body
    
    def initialize line, name, body
      @line = line
      @name = name
      @body = body
    end
    
    def to_sexp
      [:category, @name.value, @body.to_sexp]
    end
    
    def scope_implementation
      DeclareCategoryScope.new @line, @body
    end
    
    def bytecode g
      pos(g)
      
      ##
      # category = self.__category__ @name
      g.push_self
        g.push_literal @name.value
      g.send :__category__, 1
      
      scope_implementation.bytecode g
    end
  end
  
end
