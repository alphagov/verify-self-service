class AdminController < ApplicationController
  require 'net/http'
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

  # Temporary for testing purposes
  def test_connection
    url = URI.parse(params[:address])
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port,
                          use_ssl: url.scheme == 'https',
                          open_timeout: 3,
                          read_timeout: 3) { |http|
      http.request(req)
    }
    render plain: res.body
  rescue StandardError => e
    render plain: e
  end
end
