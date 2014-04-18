
%%machine lexer; # %

%%{
# %
  constant   = c_upper c_alnum+;
  identifier = c_lower c_alnum+;
  
  # Object { ... }
  #
  decl_begin = (
    constant     % { grab :constant }
    c_space_nl*  % { mark :space }
    '{'          % { grab :brace, kram(:space) }
  ) % {
    stuff :T_CONSTANT,      :constant
    stuff :T_DECLARE_BEGIN, :brace
  };
  
  # foo: { ... }
  #
  bind_begin = (
    identifier                  % { grab :identifier }
    (c_space* ':' c_space_nl*)  % { mark :space }
    '{'                         % { grab :brace, kram(:space) }
  ) % {
    stuff :T_IDENTIFIER,    :identifier
    stuff :T_BINDING_BEGIN, :brace
  };
  
  # foo: ...
  #
  binl_begin = (
    identifier                  % { grab :identifier }
    (c_space* ':' c_space*)
    ^(c_space_nl|'{')           % { fhold; grab :brace, @p, @p }
  ) % {
    stuff :T_IDENTIFIER,    :identifier
    stuff :T_BINDING_BEGIN, :brace
  };
  
  ##
  # Top level machine
  
  main := |*
    c_space_nl;
    
    decl_begin => { fcall decl_body; };
    constant   => { emit :T_CONSTANT };
    
    any => { error :main };
  *|;
  
  ##
  # Declarative body machine
  
  decl_body := |*
    c_space_nl;
    
    decl_begin => { fcall decl_body; };
    bind_begin => { fcall bind_body; };
    binl_begin => { fcall binl_body; };
    
    '}' => { emit :T_DECLARE_END; fret; };
    
    any => { error :decl_body };
  *|;
  
  ##
  # Binding body machines
  
  bind_body := |*
    c_space_nl;
    identifier => { emit :T_IDENTIFIER; };
    '}'        => { emit :T_BINDING_END; fret; };
    
    any => { error :bind_body };
  *|;
  
  binl_body := |*
    c_space;
    identifier => { emit :T_IDENTIFIER; };
    c_nl       => { emit :T_BINDING_END, @ts, @ts; fret; };
    
    any => { error :binl_body };
  *|;
  
}%%
# %