
require "rubinius/bridge"
require "rubinius/toolset"

module Myco; end

module Myco
  ToolSet = Rubinius::ToolSets.create :myco do
    require "rubinius/melbourne"
    require "rubinius/processor"
    require "rubinius/compiler"
    require "rubinius/ast"
    
    require_relative 'parser'
  end
end
