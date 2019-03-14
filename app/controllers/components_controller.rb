class ComponentsController < ApplicationController
    def index
      @components = Component.all
    end
  
    def new
      @component = NewComponentEvent.new
    end
  
    def create
      @component = NewCertificateEvent.create(component_params)
      redirect_to components_path
    end
  
    private
  
    def component_params
      params.require(:component).permit(
        :name,
        :type
      )
    end
  
  end
  