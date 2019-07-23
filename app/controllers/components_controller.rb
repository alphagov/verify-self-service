class ComponentsController < ApplicationController
  layout "main_layout"

  def index
    @sp_components = SpComponent.all
    @msa_components = MsaComponent.all
  end
end
