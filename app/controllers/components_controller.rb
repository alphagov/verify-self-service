class ComponentsController < ApplicationController
  def index
    @sp_components = SpComponent.all
    @msa_components = MsaComponent.all
  end
end
