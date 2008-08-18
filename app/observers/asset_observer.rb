class AssetObserver < ActiveRecord::Observer

  def after_save(asset)
    if asset.content.class.respond_to?("defensio?") && asset.content.class.defensio?
      if asset.description
        defensio = Defensio.new(:no_validate_key => true)
        defensio.announce_article(asset.content)
      else
        RAILS_DEFAULT_LOGGER.info "Not doing defensio-announce for asset '#{asset.name}' - no description."
      end
    end
  end

end
