module Api::V1::Concerns::ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      case e
      when Api::V1::Errors::CustomError
        log_and_render_error(
          error: 'invalid_request',
          message: e.message,
          status: :bad_request,
          log_level: :info,
          exception: e
        )
      when Api::V1::Errors::NoResultsFoundError
        log_and_render_error(
          error: 'no_results_found',
          message: e.message,
          status: :ok,
          log_level: :info,
          exception: e
        )
      when Net::OpenTimeout, Net::ReadTimeout
        log_and_render_error(
          error: 'request_timeout',
          message: 'Request timed out',
          status: :gateway_timeout,
          log_level: :error,
          exception: e
        )
      else
        log_and_render_error(
          error: 'service_unavailable',
          message: 'Unable to process restaurant search',
          status: :service_unavailable,
          log_level: :error,
          exception: e
        )
      end
    end
  end

  private

  def log_and_render_error(error:, message:, status:, log_level: :error, exception: nil)
    log_message = "#{exception.class}: #{exception.message}" if exception
    log_backtrace = exception.backtrace.join("\n") if exception&.backtrace

    case log_level
    when :info
      Rails.logger.info(log_message)
    when :error
      Rails.logger.error([log_message, log_backtrace].compact.join("\n"))
    end

    render json: {
      error: error,
      message: message
    }, status: status
  end
end 