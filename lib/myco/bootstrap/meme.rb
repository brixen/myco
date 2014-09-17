
module Myco
  class Meme
    attr_accessor :target
    attr_accessor :name
    attr_accessor :body
    attr_accessor :cache
    attr_accessor :expose
    
    def to_s
      "#<#{self.class}:#{self.name.to_s}>"
    end
    
    def inspect
      to_s
    end
    
    def initialize target, name, body=nil, &blk
      self.target = target
      self.name   = name
      self.body   = body || blk
      self.cache  = false
      self.expose = true
      
      @caches = {}
    end
    
    def body= value
      case value
      when Rubinius::Executable
        @body = value
        @body.scope.set_myco_meme self # Set meme for lexical scope
      when Proc
        block_env = value.block.dup
        block_env.change_name name
        @body = Rubinius::BlockEnvironment::AsMethod.new block_env
        value = value.dup
        value.lambda_style!
      else
        raise ArgumentError,
          "Meme body must be a Rubinius::Executable or a Proc"
      end
      
      @body
    end
    
    def bind
      return if not @expose
      
      meme = self
      @target.memes[@name] = meme
      
      hidden_name = :"meme.body #{@name}"
      Rubinius.add_method hidden_name, @body, @target, :public
      
      ##
      # This dynamic method is nearly the same as Meme#result_for
      # (but written from the perspective of the receiver)
      # implemented in bytecode to avoid forwarding to another method
      # on the call stack.
      # TODO: move this bytecode generation to a helper method 
      target.dynamic_method @name, '(myco_internal)' do |g|
        g.splat_index = 0 # *args
        
        invoke = g.new_label
        ret    = g.new_label
        
        ##
        # meme = <this meme>
        #
        g.push_literal meme
        g.set_local 1 # meme
        g.pop
        
        ##
        # caches = <this meme's @caches>
        #
        g.push_literal @caches
        g.set_local 2 # caches
        g.pop
        
        ##
        # cache_key = [obj.hash, args.hash, blk.hash]
        #
          g.push_self;     g.send :hash, 0
          g.push_local 0;  g.send :hash, 0 # args
          g.push_block;    g.send :hash, 0
        g.make_array 3
        g.set_local 3 # cache_key
        g.pop
        
        ##
        # if <meme.cache is true at time of bind>
        #   if caches.has_key?(cache_key)
        #     return caches[cache_key]
        #   end
        # end
        #
        if @cache
          g.push_local 2 # caches
            g.push_local 3 # cache_key
          g.send :has_key?, 1
          g.goto_if_false invoke
          
          g.push_local 2 # caches
            g.push_local 3 # cache_key
          g.send :[], 1
          g.goto ret
        end
        
        ##
        # result = meme.body.invoke meme.name, @target, obj, args, blk
        #
        invoke.set!
        
        g.push_self
          g.push_local 0 # *args
          g.push_block
        g.send_with_splat hidden_name, 0
        g.set_local 4 # result
        g.pop
        
        ##
        # return (caches[cache_key] = result)
        #
        g.push_local 2 # caches
          g.push_local 3 # cache_key
          g.push_local 4 # result
        g.send :[]=, 2
        
        ret.set!
        g.ret
      end
    end
    
    def result *args, &blk
      result_for target.instance, *args, &blk
    end
    
    def result_for obj, *args, &blk
      cache_key = [obj.hash, args.hash, blk.hash]
      if @cache && @caches.has_key?(cache_key)
        return @caches[cache_key]
      end
      
      result = @body.invoke @name, @target, obj, args, blk
      
      @caches[cache_key] = result
    end
    
    def set_result_for obj, result, *args, &blk
      cache_key = [obj.hash, args.hash, blk.hash]
      @caches[cache_key] = result
    end
  end
end
