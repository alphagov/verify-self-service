class ComponentsController < ApplicationController
  def index
    @components = Component.all
  end

  def new
    @component = NewComponentEvent.new
  end

  def show
    @component = Component.find(params[:id])
  end

  def create
    @component = NewComponentEvent.create(component_params)
    if @component.valid?
      redirect_to components_path
    else
      Rails.logger.info(@component.errors.full_messages)
      render :new
    end
  end

private

  def component_params
    params.require(:component).permit(
      :name,
      :component_type,
      :entity_id
    )
  end
end
