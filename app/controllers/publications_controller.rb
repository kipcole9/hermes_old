class PublicationsController < AssetsController

private

  def authorized?
    current_user.is_admin?
  end
end
