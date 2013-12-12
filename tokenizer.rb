class Tokenizer
  attr_reader :ss

  OPENING_TAG = /<([a-z]+)\s*>/i

  def initialize(io)
    @ss = StringScanner.new(io.read)
  end

  def next_token
    return if @ss.eos?
    
    case
    when tag = @ss.scan(OPENING_TAG)
      tag = tag.gsub(/<|>/,'')
      closing_regex = /<\/#{tag}>/i
      content = ""
      while !@ss.scan(closing_regex)
        content << @ss.getch
      end
      XMLTag.new(tag, content)
    end
  end

end

class XMLTag

  TAGS = []

  attr_reader :tag, :attributes, :content
  attr_accessor :children

  def initialize(tag, attributes = nil, content)
    @tag = tag
    @attributes = attributes
    @content = content
    @children = []
    create_children
    make_children_methods
    make_tag_method
    XMLTag::TAGS << self
  end

  def create_children
    if !@content.empty?
      child_io = StringIO.new(@content)
      token = Tokenizer.new(child_io)
      @children << token.next_token
      subcontent = token.ss.rest
      puts subcontent
      unless subcontent == self.content
        while !subcontent.empty?
          child_io = StringIO.new(subcontent)
          token = Tokenizer.new(child_io)
          @children << token.next_token
          subcontent = token.ss.rest
        end
      end
    end
  end

  def valid_children
    self.children.reject { |c| c.class == NilClass }
  end

  def make_children_methods
    valid_children.each do |child|
      define_singleton_method(child.tag) do
        child.content
      end
    end
  end

  def make_tag_method
    define_singleton_method(self.tag) do
      properties_hash = {}
      valid_children.each do |child|
        properties_hash[child.tag.to_sym] = self.send(child.tag)
      end

      properties_hash
    end
  end

end

### XML ###
# <note>
#   <to>Tove</to>
#   <from>Jani</from>
#   <heading>Reminder</heading>
#   <body>Don't forget me this weekend!</body>
# </note>