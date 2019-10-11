module ErrorHelper
  def error_summary_for(errors, name)
    render partial: 'shared/error_summary', locals: { errors: errors, name: name }
  end

  def error_message_on(errors, method)
    message = errors&.full_messages_for(method)&.first
    render partial: 'shared/error_messages_field', locals: { message: message }
  end
end
