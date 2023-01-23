RelationCodes = [:!, :":", :x,
                 :s0, :s1, :s2, :s3, :s4, :s5, :s6, :s7]

class Multiclass
  def initialize(classes)
    @classes = classes.flatten.map do |c|
      c = c.to_sym
=begin
      case c
      when :OP
        [:OP, :OPlong, :OPshort]
      when :CP
        [:CP, :CPlong, :CPshort]
      end
=end
    end.flatten.uniq.sort
  end
  def belongs?(q)
    if q.respond_to? :map
      (@classes & q).any?
    else
      @classes.include? q
    end
  end
  def get_classes
    @classes
  end
end

def decode_token(token)
  case token
  when "(AL|HL)";           Multiclass.new(['AL', 'HL'])
  when "(AL|HL|NU)";        Multiclass.new(['AL', 'HL', 'NU'])
  when "(BA|HY|NS)";        Multiclass.new(['BA', 'HY', 'NS'])
  when "(BK|CR|LF|NL)";     Multiclass.new(['BK', 'CR', 'LF', 'NL'])
  when "(CL|CP|EX|IS|SY)";  Multiclass.new(['CL', 'CP', 'EX', 'IS', 'SY'])
  when "(CR|LF|NL)";        Multiclass.new(['CR', 'LF', 'NL'])
  when "(ID|EB|EM)";        Multiclass.new(['ID', 'EB', 'EM'])
  when "(JL|JV|H2|H3)";     Multiclass.new(['JL', 'JV', 'H2', 'H3'])
  when "(JL|JV|JT|H2|H3)";  Multiclass.new(['JL', 'JV', 'JT', 'H2', 'H3'])
  when "(JT|H3)";           Multiclass.new(['JT', 'H3'])
  when "(JV|H2)";           Multiclass.new(['JV', 'H2'])
  when "(JV|JT)";           Multiclass.new(['JV', 'JT'])
  when "(PR|PO)";           Multiclass.new(['PR', 'PO'])
  when "(SP|ZW)";           Multiclass.new(['SP', 'ZW'])
  when "B2";    Multiclass.new(['B2'])
  when "BB";    Multiclass.new(['BB'])
  when "BK";    Multiclass.new(['BK'])
  when "CB";    Multiclass.new(['CB'])
  when "CL";    Multiclass.new(['CL'])
  when "CP";    Multiclass.new(['CP'])
  when "CR";    Multiclass.new(['CR'])
  when "EB";    Multiclass.new(['EB'])
  when "EM";    Multiclass.new(['EM'])
  when "GL";    Multiclass.new(['GL'])
  when "HL";    Multiclass.new(['HL'])
  when "HY";    Multiclass.new(['HY'])
  when "IN";    Multiclass.new(['IN'])
  when "IS";    Multiclass.new(['IS'])
  when "JL";    Multiclass.new(['JL'])
  when "JT";    Multiclass.new(['JT'])
  when "LF";    Multiclass.new(['LF'])
  when "NS";    Multiclass.new(['NS'])
  when "NU";    Multiclass.new(['NU'])
  when "OP";    Multiclass.new(['OP'])
  when "PO";    Multiclass.new(['PO'])
  when "PR";    Multiclass.new(['PR'])
  when "QU";    Multiclass.new(['QU'])
  when "SP";    Multiclass.new(['SP'])
  when "SY";    Multiclass.new(['SY'])
  when "WJ";    Multiclass.new(['WJ'])
  when "[^SP|BA|HY]";
    Multiclass.new(["AL", "B2", "BB", "BK", "CB", "CL", "CP", "CR", "EB",
                    "EM", "EX", "GL", "H2", "H3", "HL", "ID", "IN", "IS",
                    "JL", "JT", "JV", "LF", "NL", "NS", "NU", "OP", "PO",
                    "PR", "QU", "SY", "WJ", "ZW", "CM", "ZWJ", "RI"])

  when "Any";
    Multiclass.new(["AL", "B2", "BA", "BB", "BK", "CB", "CL", "CP", "CR",
                    "EB", "EM", "EX", "GL", "H2", "H3", "HL", "HY", "ID",
                    "IN", "IS", "JL", "JT", "JV", "LF", "NL", "NS", "NU",
                    "OP", "PO", "PR", "QU", "SP", "SY", "WJ", "ZW", "CM",
                    "ZWJ", "RI"])

  when "(CL|CP)";  Multiclass.new(['CL', 'CP'])
  when "(HY|BA)";  Multiclass.new(['HY', 'BA'])
  when "(CM|ZWJ)"; Multiclass.new(['CM', 'ZWJ'])
  when "CM";       Multiclass.new(['CM'])
  when "RI";       Multiclass.new(['RI'])
  when "ZW";       Multiclass.new(['ZW'])
  when "ZWJ";      Multiclass.new(['ZWJ'])
  when "[^BK|CR|LF|NL|SP|ZW]";
    Multiclass.new(["AL", "B2", "BA", "BB", "CB", "CL", "CP", "EB", "EM",
                    "EX", "GL", "H2", "H3", "HL", "HY", "ID", "IN", "IS",
                    "JL", "JT", "JV", "NS", "NU", "OP", "PO", "PR", "QU",
                    "SY", "WJ", "CM", "ZWJ", "RI"])

  when "sot"; Multiclass.new(['sot']) # a SUPERspecial class, don't mingle!

  when "(CL|CP),SP*";
  when "B2,SP*";
  when "HL,(HY|BA)";
  when "OP,SP*";
  when "ZW,SP*";

  else
    raise "unknown token: #{token}"
  end
end

# Manual maintenance, as per above
LB_AllClasses = decode_token('Any').get_classes.flatten.uniq.sort
LB_TotClasses = [LB_AllClasses, decode_token('sot').get_classes].flatten

class Pairings
  def initialize
    @pairings = Hash.new
    LB_TotClasses.each_with_index do |lklass, idcode|
      @pairings[lklass] = Hash.new
      LB_AllClasses.each do |rklass|
        @pairings[lklass][rklass] = nil
      end
      @pairings[lklass]["IDCODE"] = idcode
    end
  end
  def get(l, r)
    @pairings[l][r]
  end
  def set_pairing(l, r, p)
    [r].flatten.compact.each do |r|
      unless @pairings[l][r]
        @pairings[l][r] = p
      end
    end
  end
  def override_pairing(l, r, p)
    [r].flatten.compact.each do |r|
      @pairings[l][r] = p
    end
  end
  def is_complete?
    @pairings.values.map(&:values).flatten.find{|p| p.nil? } ? false : true
  end
  def output
    @pairings
  end
end

class Rule
  def initialize(l, x, r)
    @left = decode_token(l)
    if @left.nil? #&& ! l.include?(",")
      raise "unknown OR: #{l}"
    end
    @relation = x.to_sym
    @right = decode_token(r)
    if @right.nil? #&& ! r.include?(",")
      raise "unknown OR: #{r}"
    end
  end
  def probe_left(lklass)
    if @left && @right
      if @left.belongs?(lklass)
        return @relation, @right.get_classes
      end
    end
    return nil
  end
  def probe_both(lklass, rklass)
    if @left && @right
      if @left.belongs(lklass) && @right.belongs?(rklass)
        return @relation
      end
    end
    return nil
  end
end

Rulez = File.open("unikod-line-break3.txt", 'rb'){|fh|
  fh.read
}.split("\n").reject{|l|
  l.start_with?("LB") || l.start_with?("#")
}.map(&:split).map{|r|
  Rule.new *r
}

Pairs = Pairings.new; nil

LB_TotClasses.each do |klass|
  Rulez.each do |rule|
    p, right = rule.probe_left(klass)
    if p
      Pairs.set_pairing(klass, right, p)
    end
  end
end


def save_lbrulez
require 'yaml'



File.write("pairings.yaml", Pairs.output.to_yaml)

lbalgo_map = Array.new(LB_TotClasses.length)

Pairs.output.each_pair do |left, matchings|
  idx = LB_TotClasses.index(left)
  rels = LB_AllClasses.map do |rklass|
    matchings[rklass]
  end
  lbalgo_map[idx] = rels
end

lbalgo_map = lbalgo_map.flatten.map do |relation|
  rel = RelationCodes.index(relation)
  unless rel
    raise "unknown something or other"
  end
  rel
end

File.open("unicode-lbalgo-map.tal", "wb") do |fh|
  fh.write("@unicode-lbalgo-map\n")
  fh.write("  ( row: the LBClass of the left codepoint/sot )\n")
  fh.write("  ( collumn: the LBClass of the right codepoint )\n")

  section_size = LB_AllClasses.length

  sections = lbalgo_map.length / section_size
  if lbalgo_map.length > (sections * section_size)
    sections += 1
  end

  sections.times do |i|
    numslen = 0
    line = "  "
    line <<
      (lbalgo_map[Range.new((( i    * section_size)  ),
                            (((i+1) * section_size)-1))].map do |num|
         numslen += 1
         sprintf("%x", num)
       end.join)
    if numslen.odd?
      line << "0"
    end
    line << "\n"

    fh.write(line)
  end
end
end
