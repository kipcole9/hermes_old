class Tag < ActiveRecord::Base
  has_many :taggings
  
  validates_presence_of :name
  cattr_accessor :destroy_unused
  self.destroy_unused = false
  
  def self.find_controlled_vocabulary(tags)
    keywords = TagList.from(unsynonym(tags))
    index = 0
    tag_results = []
    puts "Looking for tags '#{tags}'" if tags.size > 0
    while index < keywords.size
      # What to do if find :all gets more than one row?  Insert in all cases, then move on
      keyword_list = Tag.find(:all, :conditions => ["name = ?", keywords[index]])
      puts "Looking for keyword '#{keywords[index]}' found #{keyword_list.size} tags."
      case keyword_list.size
      when 1
        # One entry found. Trace the hierarchy as far as possible to disambiguate later terms.
        # Store the terminal node.
        current_node = keyword_list.first
        while (index+1 < keywords.size) and (child_node = is_child?(keywords[index+1], current_node))
          puts "  Keyword '#{keywords[index+1]}' is a child of '#{keywords[index]}'."
          index += 1
          current_node = child_node
        end
        puts "  Storing keyword '#{keywords[index]}' with node [#{current_node.id.to_s}]"
        tag_results << current_node
      when 0
        # Strategy: what to do with unfound keywords?
        # Flag with error and continue.
        puts "  Keyword '#{keywords[index]}' was not found."
        UnknownTags.add(keywords[index])
      else
        # Multiple different terms of the same name in different hierarchies.
        # We choose to save references to each of them since we can't disambiguate
        # puts "Multiple terms for '#{keywords[index]}' found.  Saving each of them."
        keyword_list.each do |l|
          puts "  Storing keyword '#{keywords[index]}' with node [#{l.id.to_s}]"
          tag_results << l
        end
      end
      index += 1
    end
    return tag_results
  end
    
  def self.is_child?(child, parent_node)
    # Uses nested set lookup.  Note:
    # => It is possible to have more than one children with the same name in different parts of the
    # => hierarchy, but we only return the first one.
    # => Also: requires that the nested set is up-to-date.
    Tag.find(:first, :conditions => ["name = ? AND lft BETWEEN ? AND ?", child, parent_node.lft, parent_node.rgt])
  end
  
  # Add child node to a parent
  def self.add_child(parent, child)
    if parent.is_a?(Symbol) then parent = parent.to_s end
    node = find_node(parent)
    if node.length == 0 then
      puts "No node called '#{parent}' found.  No update performed."
      return false
    end
    
    node.each do |n|
      if child.is_a?(Array)
        child.each do |c|
          find_or_insert_child(n, c)
        end
      else
        find_or_insert_child(n, child)
      end
    end
  end
  
  def self.find_node(parent)
    parts = parent.split('>')
    parents = find(:all, :conditions => ["name = ?", parts[0]])
    return parents if parts.length == 1
    next_part = 1
    while next_part < parts.length
      if (parents = is_direct_child?(parents, parts[next_part]))
        next_part += 1
      else
        return []
      end
    end
    return parents
  end
  
  def self.is_direct_child?(parent_nodes, child)
    parent_nodes.each do |p|
      child = find(:all, :conditions => ["name = ? AND parent_id = ?", child, p.id])
      return child if child
    end
    nil
  end
  
  # Add Synonym
  def self.add_synonym(parent, synonym)
    if Synonym.find(:first, :conditions => ["name = ? and synonym = ?", parent, synonym])
      puts "Synonym '#{synonym}' for '#{parent}' already exists.  No update performed."
      return false
    end
    Synonym.create!(:name => parent, :synonym => synonym)
  end

  # Transform keyword list by reverting synonyms
  def self.unsynonym(tags)
    synonyms = {}
    tag_list = TagList.from(tags) if tags.is_a?(String)
    tag_list = tags if tags.is_a?(Array)
    Synonym.find(:all, :conditions => ["synonym in (?)", tag_list]).each {|r| synonyms[r.synonym.downcase] = r.name }
    tag_list.map!{|k| synonyms[k.downcase] ? synonyms[k] : k }.join(',')
  end
  
  # Build nested set from adjacency model
  def self.build_nested_set
    root = Tag.find(:first, :conditions => ["name = ?", "[ROOT]"])
    if root
      puts "#{Time.now}: Starting with root node [ROOT] with id #{root.id}"
      nodes = self.update_nested_set(root.id, 1)
      puts "#{Time.now}: Finished updating #{ nodes / 2} nodes."
    else
      puts "Could not find root node"
    end
  end

  # Display all the parent nodes in order
  def self.hierarchy(node)
    rows = Tag.find(:all, :conditions => ["name = ?", node])
    if rows.size > 0
      rows.each do |r|
        hierarchy = Tag.find(:all, :conditions => ["lft < ? and rgt > ?", r.lft, r.rgt], :order => "lft ASC").collect! {|r| r.name}
        puts hierarchy.join(">")
      end
      puts "Found #{rows.size} instances of #{node}."
      return true
    else
      puts "Node #{node} was not found"
      return false
    end
  end
    
  # Display the tree below this node
  def self.tree(node)
    rows = Tag.find(:all, :conditions => ["name = ?", node])
    if rows.size > 0
      rows.each do |r|
        display_tree(r)
      end
    else
      puts "Node '#{node}' was not found"
      return false
    end
    return true
  end

  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def to_s
    name
  end
  
  def count
    read_attribute(:count).to_i
  end
  
   def import_keywords
     @f = File.open("#{RAILS_ROOT}/lib/keywords.txt")
     first = Category.new(:name => "[ROOT]")
     first.save!
     indent = 0
     import_category(indent, first.id)
     @f.close
   end

   def import_category (current_indent, parent)
     while l = @f.gets do
       new_indent, new_category = analyse_line(l)
       if new_indent == indent
         c = Category.new(:name => new_category, :parent_id => parent)
         new_parent = c.id
         c.save!
       else
         c = Category.new(:name => new_category, :parent_id => new_parent)
         import_category(new_indent, new_parent)
       end
     end unless l.match(/\{/)
   end

  def analyse_line(l)
    i = l.match(/(^\t*)/).length
    c = l.sub($1,'')
  end
  
private
  
  def self.update_nested_set(parent, left)
    right = left + 1
    r = Tag.find(:all, :conditions => ["parent_id = ?", parent])
    r.each do |r|
      right = update_nested_set(r.id, right)
    end
    
    p = Tag.find_by_id(parent)
    p.lft, p.rgt = left, right
    p.save!
    
    return right+1
  end
  
  def self.display_tree(node)
    right  = []
    result = Tag.find(:all, :conditions => ["lft BETWEEN ? AND ?", node.lft, node.rgt], :order => "lft ASC")
    result.each do |r|
      while right.last < r.rgt
        right.pop
      end if right.size > 0
      puts "#{'  ' * right.size}#{r.name}"    
      right << r.rgt
    end
  end
  
  def self.find_or_insert_child(node, child)
    if Tag.find(:first, :conditions => ["parent_id = ? and name = ?", node.id, child])
      puts "Node already exists for '#{child}' in '#{node.name}' hierarchy. No update performed."
    else
      Tag.create!(:parent_id => node.id, :name => child)
    end
  end
end
