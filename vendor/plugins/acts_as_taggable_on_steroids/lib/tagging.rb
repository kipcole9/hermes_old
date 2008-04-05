class Tagging < ActiveRecord::Base #:nodoc:
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  
  # Not required for Controlled Vocabulary Implementation
  #def after_destroy
  #  if Tag.destroy_unused and tag.taggings.count.zero?
  #    tag.destroy
  #  end
  #end
end
