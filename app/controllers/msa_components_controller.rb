class MsaComponentsController < ApplicationController
  def index
    @msa_components = MsaComponent.all
  end

  def new
    @component = NewMsaComponentEvent.new
  end

  def show
    @component = MsaComponent.find_by_id(params[:id])
  end

  def create
    @component = NewMsaComponentEvent.create(component_params)
    if @component.valid?
      redirect_to root_path
    else
      Rails.logger.info(@component.errors.full_messages)
      render :new
    end
  end

private

  def component_params
    params.require(:component).permit(:name, :entity_id)
  end
end
