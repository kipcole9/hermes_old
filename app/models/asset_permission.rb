class AssetPermission < ActiveRecord::Base
  
  GROUP = YAML.load_file("#{RAILS_ROOT}/config/hermes_groups.yml")
  
  Default_read_permissions    = GROUP["owner"] + GROUP["public"]
  Default_update_permissions  = GROUP["owner"] + GROUP["admin"]
  Default_delete_permissions  = GROUP["owner"] + GROUP["admin"]
  Default_create_permissions  = GROUP["admin"]
  
  
  def self.group_others(user)
    user.groups ^ GROUP["owner"]
  end
  
  # Default set of groups a user belongs to
  def self.default_user_groups
    GROUP["owner"] + GROUP["public"]
  end
  
  def self.default_update_permission(type)
    find_by_content_type(type).default_update_permission rescue nil || Default_update_permissions
  end 
  
  def self.default_read_permission(type)
    find_by_content_type(type).default_read_permission rescue nil || Default_read_permissions
  end

  def self.default_delete_permission(type)
    find_by_content_type(type).default_delete_permission rescue nil || Default_delete_permissions
  end
  
  def self.create_permission(type)
    find_by_content_type(type).create_permission rescue nil || Default_create_permissions
  end  

  def self.can_update?(asset, user)
    ((asset.created_by == user.id) and (asset.update_permission & GROUP["owner"] > 0)) || 
      (asset.update_permissions & group_others(user) > 0) || 
      user.is_admin? ? true : false
  end

  def self.can_create?(asset_class, user)
    (create_permission(asset_class) & group_others(user) > 0) || user.is_admin? ? true : false
  end
  
  def self.can_delete?(asset, user)
    ((asset.created_by == user.id) and (asset.delete_permission & GROUP["owner"] > 0)) || 
      (asset.delete_permissions & group_others(user) > 0) || user.is_admin? ? true : false
  end

  def self.is_admin?(user)
    user.groups & GROUP["admin"] > 0
  end
end