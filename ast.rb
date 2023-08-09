require_relative("util")

class AstNode
  attr_reader(:children)
  attr_accessor(:parent)

  def initialize(rule_or_token)
    @rule_or_token = rule_or_token
    @children = []
    @parent = nil
  end

  def add_child(rule_or_token)
    self.class.new(rule_or_token).tap do |node|
      node.parent = self
      @children.push(node)
    end
  end

  def add_node_child(node)
    node.parent = self
    @children.push(node)
    node
  end

  def reject
    panic!("Rejecting root node") if @parent.nil?

    @parent.children.delete(self)
    @parent
  end
end
