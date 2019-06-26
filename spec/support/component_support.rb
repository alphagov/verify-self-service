module ComponentSupport
  def component_by_type(component_type)
    if component_type == COMPONENT_TYPE::SP
      create(:new_sp_component_event).sp_component
    else
      create(:new_msa_component_event).msa_component
    end
  end

  def alternative_component(component_type)
    if component_type == COMPONENT_TYPE::MSA
      create(:new_sp_component_event).sp_component
    else
      create(:new_msa_component_event).msa_component
    end
  end
end
