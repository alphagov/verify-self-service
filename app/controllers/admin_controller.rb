class AdminController < ApplicationController
  include ControllerConcern

  def index
    @sp_components = SpComponent.all
    @msa_components = MsaComponent.all
    @services = Service.all
    @certificates = Certificate.all
    @teams = Team.all
  end

  def publish_metadata
    event_id = "manual-#{Time.now.to_i}"
    PublishServicesMetadataEvent.create(
      event_id: event_id,
      environment: params[:environment],
    )
    check_metadata_published(event_id)
    redirect_to admin_path(anchor: :publish)
  end
end
