class MsaComponentsController < ApplicationController
  before_action :find_teams, only: %i[edit]

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

  def edit
    @msa_component = MsaComponent.find_by_id(params[:id])
  end

<<<<<<< HEAD
  def update
    msa_component = MsaComponent.find_by_id(params[:id])
    msa_component.team_id = params.dig(:component, :team_id)
    event = ChangeComponentEvent.create(
      component: msa_component
    )
    unless event.valid?
      error_message = event.errors.full_messages
      flash[:notice] = error_message
    end
    redirect_to msa_components_path
  end

private

=======
>>>>>>> f1ad9cc... Moved RBAC to Application Controller
  def component_params
    params.require(:component).permit(:name, :entity_id, :team_id)
  end

  def find_teams
    @teams = Team.all
  end
end
