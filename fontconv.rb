require './ucd_prep1'
require './unikod-line-break5'

# precalculate some things
UnicodePoints.each do |point|
  # Resolve some interesting LB classes. We don't resolve :CB.
  case point[:lb]
  when :AI, :SG, :XX
    point[:OG_lb] = point[:lb]
    point[:lb] = :AL
  when :SA
    point[:OG_lb] = point[:lb]
    if (point[:gc] == :Mn) || (point[:gc] == :Mc)
      point[:lb] = :CM
    else
      point[:lb] = :AL
    end
  when :CJ
    point[:OG_lb] = point[:lb]
    point[:lb] = :NS
  else
  end
end; nil

# sanity check
seen_lbclasses = {}
UnicodePoints.each do |point|
  seen_lbclasses[point[:lb]] = true
end; nil
if ((seen_lbclasses.keys.sort - LB_AllClasses).any?) ||
   (! LB_AllClasses.index(:AL))
  raise "unknown LB classes exist, or LB class :AL doesn't exit!"
end

# now perform the work :)
unifont_raw = File.open('unifont-15.0.01.bdf', 'rb'){|fh|
  fh.read
}.split(/\r?\n/)

unifont_chars = {};
unifont_raw.inject([:nochar,nil,{:bitmap=>[]}]){|(state,name,carry),line|
  if state == :nochar;
    if line.start_with?("STARTCHAR");
      state=:inchar;
      name = line.split(" ",2)[-1]
    end
  elsif state==:inchar;
    if line == 'ENDCHAR';
      state=:nochar;
      unifont_chars[name] = carry;
      name=nil;
      carry={:bitmap=>[]}
    elsif line.start_with?('BITMAP');
      state=:bitmap
    else
      k,v = line.split(" ", 2);
      carry[k.to_sym] = v
    end
  else
    if line == 'ENDCHAR';
      state=:nochar;
      unifont_chars[name] = carry;
      name=nil;
      carry={:bitmap=>[]}
    else
      carry[:bitmap] << line
    end
  end;
  [state,name,carry]
}


Scrolllen   = 0x1000
Maxfilesize = 0xffff
bitmap_header = [Scrolllen].pack("s>*")
bitmaps=[bitmap_header.dup];
bitmaps_taken=bitmap_header.length;
glyphs=[];
codechars = Array.new(0x10000, Array.new(8, 0).pack("C*"));

unifont_chars.to_a.each do |name, desc|
  name = /^U\+(.*)$/.match(name)[1].to_i(16);
  (dwidthx,dwidthy)=desc[:DWIDTH].split.map{|i|
    i = i.to_i;
    if i < 0;
      i = ((i*(-1))^0xff)+1 end;
    i
  };
  (bbw,bbh,bbxoff,bbyoff) = desc[:BBX].split.map{|i|
    i = i.to_i;
    if i < 0;
      i = ((i*(-1))^0xff)+1
    end;
    i
  };

  if point = UnicodePoints[name]
    if klass_gc = UnicodeAllGc.index(point[:gc])
      klass_gc += 1
    else
      klass_gc = 0
    end

    case point[:ccc]
    when 220 # below
      klass_nsmark = 1
      dwidthx = 0                            # !!!
      dwidthy = -4                           # !!!
    when 230 # above
      klass_nsmark = 2
      dwidthx = 0                            # !!!
      dwidthy = 4                            # !!!
    else
      klass_nsmark = 0
    end

    lb_klass = point[:lb]

    case lb_klass
    when :BK, :CR, :LF, :NL, :SP, :ZW
      supress = 0x80
    else
      supress = 0x00
    end

    klass = (klass_gc + (klass_nsmark << 5)) | supress
  else
    klass = 0 # means ignore this glyph
    lb_klass = :AL # technically :XX, but it gets resolved to :AL by default
  end

  lb_klass = LB_AllClasses.index(lb_klass)

  glyphmetadata=[dwidthx,dwidthy,bbw,bbxoff,bbh,bbyoff,0,0].pack("C*");
  if glyphmetadata_idx = glyphs.index{|g| g == glyphmetadata };
    nil
  else
    glyphmetadata_idx = glyphs.length;
    glyphs << glyphmetadata
  end;
  if glyphmetadata_idx >= 0x20
    raise "too many different glyph metadata combinations!"
  end
  glyphmetadata_offset = (glyphmetadata_idx << 3) & 0xff;

  bitmap=[desc[:bitmap].join].pack("H*");
  bitmap_len = bitmap.length;

  modulo_scrolllen = bitmaps_taken % Scrolllen
  remains_len = (Scrolllen - modulo_scrolllen)

  fitsinto_scroll = (bitmap_len <= remains_len)
  fitsinto_file   = ((bitmaps_taken + bitmap_len) <= Maxfilesize)
  fitsinto_enlarged_file = ((bitmaps_taken + bitmap_len + remains_len) <=
                               Maxfilesize)

  if (fitsinto_scroll && fitsinto_file)
  elsif (fitsinto_file && fitsinto_enlarged_file)
    bitmaps[-1] << Array.new(remains_len, 0).pack("C*")
    bitmaps_taken += remains_len
  else
    bitmaps << bitmap_header.dup
    bitmaps_taken = bitmap_header.length
  end
  bitmap_offset = ((bitmaps.length-1) << 16) + bitmaps_taken
  bitmaps[-1] << bitmap
  bitmaps_taken += bitmap_len

  # klass == 0 means to ignore the glyph
  res = [klass, lb_klass, 0, glyphmetadata_offset,
         bitmap_offset].pack("C4i>");
  codechars[name] = res
end; nil


bitmaps.each_with_index{|bitmap,idx|
  fn=sprintf("db/bitmap.unifont.%04x", idx);
  File.open(fn, 'wb'){|fh|
    fh.write(bitmap)
  }
}; nil

File.open("db/glyphmetadata.unifont.0000", 'wb'){|fh|
  fh.write(glyphs.join)
}

File.open("unicode-layouter-glyphmetadata.tal", "wb") do |fh|
  fh.write("@unifont-glyphmetadata\n")

  section_size = 16
  glyphdata = glyphs.join.unpack("C*")
  sections = glyphdata.length / section_size
  if glyphdata.length > (sections * section_size)
    sections += 1
  end

  sections.times do |i|
    line = " "
    line << (glyphdata[Range.new((( i    * section_size)  ),
                                 (((i+1) * section_size)-1))].map do |num|
               sprintf(" %02x", num)
             end).join
    line << "\n"

    fh.write(line)
  end
end

bunch=0x2000;
((codechars.length/bunch)+(((codechars.length%bunch)>0)?1:0)).times {|i|
  j=i*bunch;
  codes = codechars[Range.new(j, j+(bunch-1))].join;
  fn=sprintf("db/codechar.unifont.%02x", i);
  File.open(fn,'wb'){|fh|
    fh.write(codes)
  }
}

save_lbrulez
