
module Myco::ToolSet
  class Parser < Rubinius::ToolSets::Runtime::Melbourne
  end
  
  class Compiler
    class Parser
      
      old_init = instance_method :initialize
      
      define_method :initialize do |*args|
        old_init.bind(self).call *args
        @processor = Myco::ToolSet::Parser
      end
    end
  end
end

require_relative 'parser/lexer'
require_relative 'parser/lexer_common'
require_relative 'parser/builder'

module Myco::ToolSet
  class Parser
    
    def parse_string string
      @builder ||= Myco::ToolSet::Parser::Builder.new.tap do |b|
        b.processor = self
      end
      
      @builder.parse string
      # klass     = process_const 1, :A
      # sendwargs = process_call  1, klass, :new, nil
      
      # sendwargs
    end
    
  end
end