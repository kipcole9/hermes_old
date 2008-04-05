module HermesKeywordsImport

  # Import Controlled Vocabulary (text file, tab indents indicate tree depth)
  #def import_keywords
  ##  @i = 0
  #  @f = File.open("#{RAILS_ROOT}/lib/keywords.txt")
  #  first = Tag.new(:name => "[ROOT]", :parent_id => 0)
  #  first.save!
  #  indent = -1
  #  @l = @f.gets
  #  @stack = []
  #  @stack << {:indent => indent, :parent => first.id, :prior_parent => 0, :category => "[ROOT]"}
  #  Tag.delete_all
  #  Synonym.delete_all
  #  import_category
  #  @f.close
  #end
  
  def import_category
    while @l
      indent, category = analyse_line(@l)
      if !Tag.match(/\{/)
        # puts "Stack depth: #{@stack.size}; Category:#{category}; Indent: #{indent}, Current Indent: #{@stack.last[:indent]}" if indent >= @stack.last[:indent]      

        # Indented level - always one level (can't have an empty level)
        if indent > @stack.last[:indent]
          c = Tag.new(:name => category, :parent_id => @stack.last[:parent])
          c.save!
          @last_category = category
          @l = @f.gets
          @stack << {:indent => indent, :parent => c.id, :prior_parent => @stack.last[:parent], :category => category}
          import_category
          @stack.pop
        end
        
        return if @stack.size == 0
        
        # Same level
        if indent == @stack.last[:indent]
          c = Tag.new(:name => category, :parent_id => @stack.last[:prior_parent])
          c.save!
          @stack.last[:parent] = c.id
          @last_category = category
        end
        
        # Unindented level.  Can jump back many levels, hence the stack popping
        if indent < @stack.last[:indent]
          while indent < @stack.last[:indent] do
            @stack.pop
          end
        else
          @l = @f.gets
        end
      else
        # Its a synonym - process it
        synonym = Tag.sub("\{",'').sub("\}",'')
        s = Synonym.new(:name => @last_category, :synonym => synonym)
        begin
           !s.save
        rescue
          puts "Probable duplicate synonym '#{synonym}' for category '#{@last_category}' (perfectly OK for this to happen most times)."
        end
        @l = @f.gets
      end
    end
  end
     
  def analyse_line(l)
    l.match(/(^\t*)/)
    i = $1.length
    c = l.sub($1,'').gsub(/(\n|\r|\t)/,'')
    return i, c
  end

end
