class UploadsController < AssetsController
  require 'cgi'
  prepend_before_filter :collect_filename
  skip_before_filter    :retrieve_assets, 
                        :retrieve_parent_assets, :create_asset, :set_sidebars,
                        :remember_location, :log_show

  skip_before_filter    :verify_authenticity_token
  
  
private
  def retrieve_this_asset
    if @object = Image.viewable_by(current_user).find_by_filename(collect_filename)
      @image = @object
      @asset = @image.asset
    end
  end
       
  def collect_filename
    @filename ||= CGI.unescape(File.basename("#{params[:id]}.#{params[:format]}"))
  end
  
  def authorized?
    case params[:action]
    when "update"
      if @object
        @object.can_update?(current_user)
      else
        AssetPermission.can_create?("Image", current_user)
      end
    else
      true
    end
  end
end