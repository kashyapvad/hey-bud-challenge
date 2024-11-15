class OpenAiClient
  include HTTParty
  base_uri ENV['OPEN_AI_API_BASE_URL']

  @base_headers = {
    "Authorization" => "Bearer #{ENV['OPEN_AI_API_KEY']}",
    "Content-Type" => "application/json"
  }

  @assistant_headers = @base_headers.merge({"OpenAI-Beta" => "assistants=v2"})

  def self.send_prompt prompt, options={}
    opts = options.with_indifferent_access
    model = opts[:model] || "gpt-4o-mini"
    body = {
      model: model,
      messages: [{ role: "user", content: prompt }]
    }.to_json
    post("/chat/completions", headers: @base_headers, body: body).with_indifferent_access
  end

  
  # If we need to use an assistant specifically made for enriching restaurants, we can use thses methods.
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