class TeamsController < ApplicationController
  before_action :find_components, only: %i[show]
  def index
    @teams = Team.all
  end

  def new
    @team = NewTeamEvent.new
  end

  def create
    team_event = NewTeamEvent.create(team_params)
    @team = team_event.team
    if @team.valid? && team_event.valid?
      flash.now[:success] = "#{@team.name} #{t('team.new.success')}."

      redirect_to teams_path
    else
      @team.errors.merge!(team_event.errors)
      Rails.logger.info(@team.errors.full_messages)
      render :new
    end
  end

  def team_params
    params.require(:team).permit(:name)
  end

  def find_components
    @components = Component.all
  end
end
