module AdminHelper
  def certificate_component_url(component_type, component_id)
    component_type == COMPONENT_TYPE::SP ? sp_component_path(component_id) : msa_component_path(component_id)
  end

  def service_sp_component_url(service)
    service.sp_component_id.nil? ? 'No SP configured' : (link_to service.sp_component_id, sp_component_path(service.sp_component_id))
  end

  def service_msa_component_url(service)
    service.msa_component_id.nil? ? 'No MSA configured' : (link_to service.msa_component_id, msa_component_path(service.msa_component_id))
  end
end
