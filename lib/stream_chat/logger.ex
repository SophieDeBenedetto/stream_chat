defmodule StreamChat.Logger.Backend do
  @levels %{
    fatal: 0,
    error: 1,
    warn: 2,
    info: 3,
    debug: 4,
    trace: 5
  }

  def init({__MODULE__, options}) do
    {:ok, Keyword.merge([group: __MODULE__, format: :plaintext], options)}
  end

  def handle_event(
        {level, _gl, {Logger, message, _timestamp, metadata}},
        options
      ) do
    case metadata[:application] do
      nil ->
        log_event(level, message, metadata, options)

      application ->
        log_event_for_application(
          @levels[level],
          @levels[options[:application_config][application][:level_lower_than]],
          message,
          metadata,
          options
        )
    end

    {:ok, options}
  end

  def log_event_for_application(level, level_lower_than, message, metadata, options)
      when level <= level_lower_than do
    Appsignal.Logger.log(
      3,
      to_string(metadata[:group] || options[:group]),
      IO.chardata_to_string(message),
      Enum.into(metadata, %{}),
      options[:format]
    )
  end

  def log_event_for_application(_level, _level_lower_than, _message, _metadata, _options),
    do: :noop

  def log_event(level, message, metadata, options) do
    Appsignal.Logger.log(
      level,
      to_string(metadata[:group] || options[:group]),
      IO.chardata_to_string(message),
      Enum.into(metadata, %{}),
      options[:format]
    )
  end
end
