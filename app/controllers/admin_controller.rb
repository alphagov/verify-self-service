class AdminController < ApplicationController
  def index
    @sp_components = SpComponent.all
    @msa_components = MsaComponent.all
    @services = Service.all
    @certificates = Certificate.all
    @teams = Team.all
  end
end
