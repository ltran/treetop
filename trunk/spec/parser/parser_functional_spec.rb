require 'rubygems'
require 'spec'

dir = File.dirname(__FILE__)
require "#{dir}/../spec_helper"

describe "A parser for a grammar that contains only atomic symbols" do
  before do
    @grammar = Grammar.new
    
    terminal = TerminalSymbol.new("bar")
    nonterminal = NonterminalSymbol.new(:foo, @grammar)
    parse_rule = ParsingRule.new(nonterminal, terminal)
    
    @grammar.add_parsing_rule(parse_rule)
    @parser = @grammar.new_parser
  end
  
  it "returns a kind of SyntaxNode upon a successful parse" do
    input = "bar"
    @parser.parse(input).should be_a_kind_of(SyntaxNode)
  end
  
  it "returns a SyntaxNode with a text value equal to the input upon a successful parse" do
    input = "bar"
    @parser.parse(input).text_value.should == input
  end
end

describe "A parser for a simple arithmetic grammar" do
  before do
    @grammar = Grammar.new
    
    additive = @grammar.nonterminal_symbol(:additive)
    multitive = @grammar.nonterminal_symbol(:multitive)
    primary = @grammar.nonterminal_symbol(:primary)
    decimal = @grammar.nonterminal_symbol(:decimal)
    nonzero_digit = @grammar.nonterminal_symbol(:nonzero_digit)
    digit = @grammar.nonterminal_symbol(:digit)
    
    # additive <= multitive "+" additive / multitive
    additive_exp = OrderedChoice.new([Sequence.new([multitive, TerminalSymbol.new("+"), additive]),
                                      multitive])
    @grammar.add_parsing_rule(additive, additive_exp)
    
    # multitive <= primary "*" multitive / primary
    multitive_exp = OrderedChoice.new([Sequence.new([primary, TerminalSymbol.new("*"), multitive]),
                                      primary])                                      
    @grammar.add_parsing_rule(multitive, multitive_exp)
    

    
    # primary <= "(" additive ")" / decimal
    primary_exp = OrderedChoice.new([Sequence.new([TerminalSymbol.new("("), additive, TerminalSymbol.new(")")]),
                                     decimal])
    @grammar.add_parsing_rule(primary, primary_exp)
    
    # decimal <= nonzero_digit digit* / "0"
    decimal_exp = OrderedChoice.new([Sequence.new([nonzero_digit, ZeroOrMore.new(digit)]),
                                     TerminalSymbol.new("0")])
    @grammar.add_parsing_rule(decimal, decimal_exp)
    
    # nonzero_digit <= 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9
    nonzero_digit_exp = OrderedChoice.new((1..9).collect { |d| TerminalSymbol.new(d.to_s) })
    @grammar.add_parsing_rule(nonzero_digit, nonzero_digit_exp)
    
    # digit <= 0 / 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9
    digit_exp = OrderedChoice.new((0..9).collect { |d| TerminalSymbol.new(d.to_s) })
    @grammar.add_parsing_rule(digit, digit_exp)
    
    @parser = @grammar.new_parser
  end
  
  it "succeeds for a single digit decimal" do
    @parser.parse("5").should be_success
  end
  
  it "succeeds for a multi-digit decimal" do
    @parser.parse("5346").should be_success
  end
  
  it "fails for a multi-digit decimal that begins with zero" do
    @parser.parse("05346").should be_failure
  end
  
  it "fails for a multi-digit decimal that ends with characters" do
    @parser.parse("05346xs").should be_failure
  end
  
  it "succeeds for a parenthesized decimal" do
    @parser.parse("(53)").should be_success
  end
  
  it "fails for a partially partially decimal" do
    @parser.parse("(53").should be_failure
  end
  
  it "succeeds for a multiplication" do
    @parser.parse("45*4").should be_success
  end
  
  it "fails for a partial multiplication" do
    @parser.parse("53*").should be_failure
  end
  
  it "succeeds for an addition" do
    @parser.parse("45+4").should be_success
  end
  
  it "succeeds for an expression with nested multiplication and addition" do
    @parser.parse("((34*10)+(44*(6*(67+(5)))))").should be_success
  end
end

describe "A parser for a grammar that contains only atomic symbols" do
  before do
    @grammar = Grammar.new
    
    terminal = TerminalSymbol.new("bar")
    nonterminal = NonterminalSymbol.new(:foo, @grammar)
    parse_rule = ParsingRule.new(nonterminal, terminal)
    
    @grammar.add_parsing_rule(parse_rule)
    @parser = @grammar.new_parser
  end
  
  it "returns a kind of SyntaxNode upon a successful parse" do
    input = "bar"
    @parser.parse(input).should be_a_kind_of(SyntaxNode)
  end
  
  it "returns a SyntaxNode with a text value equal to the input upon a successful parse" do
    input = "bar"
    @parser.parse(input).text_value.should == input
  end
end

describe "A parser for a simple arithmetic grammar with method definitions" do
  module BinaryOperator
      def left_arg
        elements[0]
      end
      
      def right_arg
        elements[2]
      end
      
      def value
        operator.call(left_arg.value, right_arg.value)
      end
  end
  
  before do
    @grammar = Grammar.new
    
    additive = @grammar.nonterminal_symbol(:additive)
    multitive = @grammar.nonterminal_symbol(:multitive)
    primary = @grammar.nonterminal_symbol(:primary)
    decimal = @grammar.nonterminal_symbol(:decimal)
    nonzero_digit = @grammar.nonterminal_symbol(:nonzero_digit)
    digit = @grammar.nonterminal_symbol(:digit)
    
    # additive <= multitive "+" additive { class_name :AdditiveExpression } / multitive
    additive_exp_choice_1 = Sequence.new([multitive, TerminalSymbol.new("+"), additive])
    additive_exp_choice_1.node_class_eval do
      include BinaryOperator      
      def operator
        lambda { |x, y| x + y  }
      end
    end
    additive_exp = OrderedChoice.new([additive_exp_choice_1,
                                      multitive])                            
    @grammar.add_parsing_rule(additive, additive_exp)
    
    # multitive <= primary "*" multitive / primary
    multitive_exp_choice_1 = Sequence.new([primary, TerminalSymbol.new("*"), multitive])
    multitive_exp_choice_1.node_class_eval do
      include BinaryOperator
      def operator
        lambda { |x, y| x * y }
      end
    end
    multitive_exp = OrderedChoice.new([multitive_exp_choice_1,
                                      primary])
    @grammar.add_parsing_rule(multitive, multitive_exp)

    
    # primary <= "(" additive ")" / decimal
    primary_exp_choice_1 = Sequence.new([TerminalSymbol.new("("), additive, TerminalSymbol.new(")")])
    primary_exp_choice_1.node_class_eval do
      def subexpression
        elements[1]
      end
      
      def value
        subexpression.value
      end
    end
    primary_exp = OrderedChoice.new([primary_exp_choice_1,
                                     decimal])
    @grammar.add_parsing_rule(primary, primary_exp)

    # decimal <= nonzero_digit digit* / "0"
    decimal_exp_choice_1 = Sequence.new([nonzero_digit, ZeroOrMore.new(digit)])
    decimal_exp_choice_1.node_class_eval do
      def value
        text_value.to_i
      end
    end
    decimal_exp_choice_2 = TerminalSymbol.new("0")
    decimal_exp_choice_2.node_class_eval do
      def value
        0
      end
    end
    decimal_exp = OrderedChoice.new([decimal_exp_choice_1, decimal_exp_choice_2])
    @grammar.add_parsing_rule(decimal, decimal_exp)
    
    # nonzero_digit <= 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9
    nonzero_digit_exp = OrderedChoice.new((1..9).collect { |d| TerminalSymbol.new(d.to_s) })
    @grammar.add_parsing_rule(nonzero_digit, nonzero_digit_exp)
    
    # digit <= 0 / 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9
    digit_exp = OrderedChoice.new((0..9).collect { |d| TerminalSymbol.new(d.to_s) })
    @grammar.add_parsing_rule(digit, digit_exp)
    
    @parser = @grammar.new_parser
  end
  
  it "returns a result has the correct value for a digit" do
    @parser.parse("5").value.should == 5
  end
  
  it "succeeds for a multi-digit decimal" do
    @parser.parse("5346").value.should == 5346
  end
    
  it "succeeds for a parenthesized decimal" do
    @parser.parse("(53)").value.should == 53
  end
  
  it "succeeds for a multiplication" do
    @parser.parse("45*4").value.should == 180
  end
  
  it "succeeds for an addition" do
    @parser.parse("45+4").value.should == 49
  end
  
  it "succeeds for an expression with nested multiplication and addition" do
    @parser.parse("(34+(44*(6*(67+(5)))))").value.should == 19042
  end
end

describe "A parser for grammar with a single terminal symbol" do
  before do
    grammar = Grammar.new do
      rule :foo, exp("foo")
    end
    @parser = grammar.new_parser
  end
  
  it "parses a matching input successfully after failing to parse nonmatching input" do
    @parser.parse("bar").should be_failure
    @parser.parse("foo").should be_success
  end
end