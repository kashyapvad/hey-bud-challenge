class GptClient
  include HTTParty
  base_uri ENV['BASE_URL']

  CREATE_AND_RUN_THREAD_ENDPOINT = "/threads/runs"

  @base_headers = {
    "Authorization" => "Bearer #{ENV['OPEN_AI_API_KEY']}"
  }

  @assistant_headers = @base_headers.merge({"OpenAI-Beta" => "assistants=v2", "Content-Type" => "application/json"})

  def self.create_thread_and_run_assistant assistant, messages, options={}
    body = {
      assistant_id: assistant,
      thread: {
        messages: messages
      }
    }.to_json
    post("/threads/runs", headers: @assistant_headers, body: body).with_indifferent_access
  end

  def self.messages thread_id
    get("/threads/#{thread_id}/messages", headers: @assistant_headers).with_indifferent_access
  end

  def self.upload_file path
    f = File.open(path, 'rb')
    body = {
      purpose: "assistants",
      file: f
    }
    post("/files", headers: @base_headers, body: body).with_indifferent_access
  end

end