
require 'myco/toolset'
require 'myco/parser'


describe Myco::ToolSet::Parser::Lexer do
  
  def self.lex string, print=false, &block
    expected = block.call if block
    describe expected do
      it "is lexed from code: \n\n#{string}\n\n" do
        tokens = Myco::ToolSet::Parser::Lexer.new(string).lex
        (puts; pp tokens) if print
        tokens.should eq expected if expected
      end
    end
    
    this_spec = self
    
    string.instance_eval do
      define_singleton_method :parse do |expected|
        this_spec.parse string, print do expected end
      end
    end
    
    string
  end
  
  def self.parse string, print=false, &block
    expected = block.call if block
    
    describe expected do
      it "is parsed from code: \n\n#{string}\n\n" do
        ast = Myco::ToolSet::Parser.new('(eval)', 1, []).parse_string string
        (puts; pp ast) if print
        ast.to_sexp.should eq expected if expected
      end
    end
  end
  
  
  describe "Constants" do
    
    lex "Object"  do [[:T_CONSTANT, "Object", 1]]  end.parse [:const, :Object]
    lex "OBJECT"  do [[:T_CONSTANT, "OBJECT", 1]]  end.parse [:const, :OBJECT]
    lex "Obj_3cT" do [[:T_CONSTANT, "Obj_3cT", 1]] end.parse [:const, :Obj_3cT]
    
  end
  
  
  describe "Declarations" do
    
    lex "Object { }" do
      [[:T_CONSTANT, "Object", 1],
       [:T_DECLARE_BEGIN, "{", 1],
       [:T_DECLARE_END, "}", 1]]
    end
    
    lex "Object{}" do
      [[:T_CONSTANT, "Object", 1],
       [:T_DECLARE_BEGIN, "{", 1],
       [:T_DECLARE_END, "}", 1]]
    end
    
    lex <<-code do
      Object {
        
      }
    code
      [[:T_CONSTANT, "Object", 1],
       [:T_DECLARE_BEGIN, "{", 1],
       [:T_DECLARE_END, "}", 3]]
    end
    
    lex <<-code do
      Object
      {
        
      }
    code
      [[:T_CONSTANT, "Object", 1],
       [:T_DECLARE_BEGIN, "{", 2],
       [:T_DECLARE_END, "}", 4]]
    end
    
  end
  
  
  describe "Bindings" do
    
    lex <<-code do
      Object {
        foo:    one
        bar  :  two  
        baz    :three
        all:zero
      }
    code
      [[:T_CONSTANT, "Object", 1], [:T_DECLARE_BEGIN, "{", 1],
       [:T_IDENTIFIER, "foo", 2],  [:T_BINDING_BEGIN, "", 2],
         [:T_IDENTIFIER, "one", 2],  [:T_BINDING_END, "", 3],
       [:T_IDENTIFIER, "bar", 3],  [:T_BINDING_BEGIN, "", 3],
         [:T_IDENTIFIER, "two", 3],  [:T_BINDING_END, "", 4],
       [:T_IDENTIFIER, "baz", 4],  [:T_BINDING_BEGIN, "", 4],
         [:T_IDENTIFIER, "three", 4],[:T_BINDING_END, "", 5],
       [:T_IDENTIFIER, "all", 5],  [:T_BINDING_BEGIN, "", 5],
         [:T_IDENTIFIER, "zero", 5], [:T_BINDING_END, "", 6],
       [:T_DECLARE_END, "}", 6]]
    end
    
    lex <<-code do
      Object {
        foo:  {  one  }
        bar  :{  two  }
        baz    :{three}  
        all:{zero }
      }
    code
      [[:T_CONSTANT, "Object", 1], [:T_DECLARE_BEGIN, "{", 1],
       [:T_IDENTIFIER, "foo", 2],  [:T_BINDING_BEGIN, "{", 2],
         [:T_IDENTIFIER, "one", 2],  [:T_BINDING_END, "}", 2],
       [:T_IDENTIFIER, "bar", 3],  [:T_BINDING_BEGIN, "{", 3],
         [:T_IDENTIFIER, "two", 3],  [:T_BINDING_END, "}", 3],
       [:T_IDENTIFIER, "baz", 4],  [:T_BINDING_BEGIN, "{", 4],
         [:T_IDENTIFIER, "three", 4],[:T_BINDING_END, "}", 4],
       [:T_IDENTIFIER, "all", 5],  [:T_BINDING_BEGIN, "{", 5],
         [:T_IDENTIFIER, "zero", 5], [:T_BINDING_END, "}", 5],
       [:T_DECLARE_END, "}", 6]]
    end
    
    lex <<-code do
      Object {
        foo: {
          one
        }
        bar:{ two
          }
        baz  :{
          three}
        all: \
          zero
      }
    code
      [[:T_CONSTANT, "Object", 1], [:T_DECLARE_BEGIN, "{", 1],
      [:T_IDENTIFIER, "foo", 2],   [:T_BINDING_BEGIN, "{", 2],
        [:T_IDENTIFIER, "one", 3],   [:T_BINDING_END, "}", 4],
      [:T_IDENTIFIER, "bar", 5],   [:T_BINDING_BEGIN, "{", 5],
        [:T_IDENTIFIER, "two", 5],   [:T_BINDING_END, "}", 6],
      [:T_IDENTIFIER, "baz", 7],   [:T_BINDING_BEGIN, "{", 7],
        [:T_IDENTIFIER, "three", 8], [:T_BINDING_END, "}", 8],
      [:T_IDENTIFIER, "all", 9],   [:T_BINDING_BEGIN, "", 9],
        [:T_IDENTIFIER, "zero", 9],  [:T_BINDING_END, "", 10],
      [:T_DECLARE_END, "}", 10]]
    end
    
  end
  
end
