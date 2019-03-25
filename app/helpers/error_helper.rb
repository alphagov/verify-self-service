module ErrorHelper
  def error_messages_for(errors)
    render partial: 'shared/error_messages', locals: { errors: errors}
  end
  def error_message_on(errors, method)
    message = errors&.full_messages_for(method)&.first
    render partial: 'shared/error_messages_field', locals: { message: message }
  end
end
