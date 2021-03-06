
module Myco
  module PrimitiveInstanceMethods
    # These methods are taken from Ruby's Kernel.
    # TODO: Audit which of these should remain.
    
    def __set_ivar__ sym, value
      Rubinius.primitive :object_set_ivar
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_set_ivar failed"
    end
    
    def __get_ivar__ sym
      Rubinius.primitive :object_get_ivar
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_get_ivar failed"
    end
    
    def __ivar_defined__ sym
      Rubinius.primitive :object_ivar_defined
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_ivar_defined failed"
    end
    
    def __kind_of__ mod
      Rubinius.primitive :object_kind_of
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_kind_of failed"
    end
    
    def __class__
      Rubinius.primitive :object_class
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_class failed"
    end
    
    def __dup__ # TODO: remove
      copy = Rubinius::Type.object_class(self).allocate
      Rubinius.invoke_primitive :object_copy_object, copy, self
      copy
    end

    def __hash__
      Rubinius.primitive :object_hash
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_hash failed"
    end
    
    # These methods are taken from Ruby's BasicObject.
    # TODO: Audit which of these should remain.
    
    def __send__ message, *args
      Rubinius.primitive :object_send
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_send failed"
    end

    def __id__
      Rubinius.primitive :object_id
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_id failed"
    end
    
    def __ivar_names__
      Rubinius.primitive :object_ivar_names
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_ivar_names failed"
    end
    
    def __equal__(other)
      Rubinius.primitive :object_equal
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_equal failed"
    end
  end
  
  module InstanceMethods
    include PrimitiveInstanceMethods
    
    def component
      __component__
    end
    
    def parent
      __component__.parent && __component__.parent.instance
    end
    
    def parent_meme
      __component__.parent_meme
    end
    
    def memes
      __component__.memes
    end
  end
  
  Instance = Class.new nil do
    include InstanceMethods
    
    # These are not included in InstanceMethods because they should not shadow
    # existing method definitions when extended into an existing object. 
    
    def method_missing name, *args
      msg = "#{to_s} has no method called '#{name}'"
      ::Kernel.raise ::NoMethodError.new(msg, name, args)
    end
    
    def to_s
      "#<#{__component__.to_s}>"
    end
    
    def inspect(pretty: true)
      vars = __ivar_names__.map { |var|
        [var.to_s[1..-1], __get_ivar__(var).inspect].join(": ")
      }
      
      vars = if vars.empty?
        ""
      elsif vars.size == 1
        vars.first
      elsif !pretty
        vars.join(", ")
      else
        "\n  " + vars.join("\n").gsub("\n", "\n  ") + "\n"
      end
      
      "#{__component__.to_s}#(#{vars})"
    end
    
    alias_method :hash,   :__hash__   # TODO: remove?
    alias_method :equal?, :__equal__  # TODO: remove?
    alias_method :==,     :__equal__  # TODO: remove?
    
    def != other
      self == other ? false : true
    end
    
    alias_method :"!", :false?
  end
  
end
