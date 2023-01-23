UnicodePoints = Array.new(0x10ffff+1) do |i| # I can *hear* the screams...
  point = Hash.new

  # Default values
  point[:gc] = :Cn # Unassigned
  point[:ccc] = 0  # Not reordered
  point[:lb] = case
               when begin [
                           Range.new(0x3400, 0x4DBF),
                           Range.new(0x4E00, 0x9FFF),
                           Range.new(0xF900, 0xFAFF)
                          ].find{|r| r.include?(i) } end
                 :ID
               when begin [
                           Range.new(0x20000, 0x2FFFD),
                           Range.new(0x30000, 0x3FFFD)
                          ].find{|r| r.include?(i) } end
                 :ID
               when begin [
                           Range.new(0x1F000, 0x1FAFF),
                           Range.new(0x1FC00, 0x1FFFD)
                          ].find{|r| r.include?(i) } end
                 :ID
               when begin [
                           Range.new(0x20A0, 0x20CF)
                          ].find{|r| r.include?(i) } end
                 :PR
               else
                 :XX
               end

  point
end

def assign_to_point_sym(file, property)
  unicode_db_regex = /^(\S+)\s*;\s*(\S+)\b/
  res = Hash.new

  File.read(file).split("\n").reject{|l|
    l.start_with?("#") ||
    l.empty?
  }.each{|l|
    m = unicode_db_regex.match(l)
    codes, prop = m[1..-1]

    prop = prop.to_sym                            # here

    codes_arry = codes.split("..")
    Range.new(codes_arry[0].to_i(16), codes_arry[-1].to_i(16)).each do |code|
      UnicodePoints[code][property] = prop
    end

    res[prop] = true
  }
  res.keys.sort
end

def assign_to_point_num(file, property)
  unicode_db_regex = /^(\S+)\s*;\s*(\S+)\b/
  res = Hash.new

  File.read(file).split("\n").reject{|l|
    l.start_with?("#") ||
    l.empty?
  }.each{|l|
    m = unicode_db_regex.match(l)
    codes, prop = m[1..-1]

    prop = prop.to_i                               # here

    codes_arry = codes.split("..")
    Range.new(codes_arry[0].to_i(16), codes_arry[-1].to_i(16)).each do |code|
      UnicodePoints[code][property] = prop
    end

    res[prop] = true
  }
  res.keys.sort
end

UnicodeAllGc  = assign_to_point_sym(
                  "UCD/extracted/DerivedGeneralCategory.txt",
                  :gc)
UnicodeAllCcc = assign_to_point_num(
                  "UCD/extracted/DerivedCombiningClass.txt",
                  :ccc)
UnicodeAllLB  = assign_to_point_sym(
                  "UCD/LineBreak.txt",
                  :lb)

