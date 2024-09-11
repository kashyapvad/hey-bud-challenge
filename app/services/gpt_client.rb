class GptClient
  include HTTParty
  base_uri ENV['BASE_URL']

  CREATE_AND_RUN_THREAD_ENDPOINT = "/threads/runs"

  @base_headers = {
    "Authorization" => "Bearer #{ENV['OPEN_AI_API_KEY']}",
    "Content-Type" => "application/json",
  }

  @assistant_headers = @base_headers.merge({"OpenAI-Beta" => "assistants=v2"})

  def self.create_thread_and_run_assistant assistant, messages, options={}
    body = {
      assistant_id: assistant,
      thread: {
        messages: messages
      }
    }
    post("/threads/runs", headers: @assistant_headers, body: body).with_indifferent_access
  end

  def self.messages thread_id
    get("/#{thread_id}/messages", headers: @assistant_headers).with_indifferent_access
  end

end