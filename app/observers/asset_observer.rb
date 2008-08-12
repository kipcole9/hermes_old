class AssetObserver < ActiveRecord::Observer

  def after_save(asset)
    if asset.content.class.respond_to?("defensio?") && asset.content.class.defensio?
      defensio = Defensio.new(:no_validate_key => true)
      defensio.announce_article(asset.content)
    end
  end

end
