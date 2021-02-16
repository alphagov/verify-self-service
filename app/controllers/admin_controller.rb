class AdminController < ApplicationController
  include ControllerConcern

  def index
    @sp_components = SpComponent.all
    @msa_components = MsaComponent.all
    @services = Service.all
    @certificates = Certificate.all
    teams = Team.all
    @relying_parties = []
    @identity_providers = []
    @other = []
    teams.each do |team|
      if team.team_type == "rp"
        @relying_parties << team
      elsif team.team_type == "idp"
        @identity_providers << team
      else
        @other << team
      end
    end
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
