class Plan
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: :string
  field :email, type: :string
  field :report_sheet_id, type: :string
  field :file, type: :string
  field :thread, type: :string #can be used to remmeber the context and enhance the report accuracy
  field :report_complete, type: :boolean, default: false
  field :compliance_report, type: :hash, default: {}

  belongs_to :governing_body, index: true

  validates :governing_body, presence: true

  before_save :format_email, if: -> { email_changed? }
  after_create :generate_report

  def generate_report
    return unless file
    set report_complete: false
    ComplianceReportService.generate_report self
  end
  
  def update_report report
    return unless report.present?
    rep = report.with_indifferent_access
    r = self.compliance_report || {}
    r[:parameters] ||= []
    r[:summary] ||= []
    r[:parameters] += rep[:report].map do |h| 
      h.transform_keys do |k| 
        key = k.downcase.to_key
        key = "extracted/analyzed_value" if key.eql? "extracted_value/analyzed_value"
        key
      end
    end
    r[:summary] += rep[:summary]
    set compliance_report: r
    CsvExporterService.export_compliance_report self
    share_sheet if check_if_report_is_complete? and compliance_report.present?
  end

  def google_sheet_link
    "https://docs.google.com/spreadsheets/d/#{report_sheet_id}"
  end

  def check_if_report_is_complete?
    s = Sidekiq::ScheduledSet.new
    b = Sidekiq::Workers.new
    r = Sidekiq::RetrySet.new
    q = Sidekiq::Queue.new("reports")

    j_count = s.select{|j| j.queue.eql? "reports" and j.args.first.eql? self.id.to_s}.count
    j_count += r.select{|j| j.queue.eql? "reports" and j.args.first.eql? self.id.to_s}.count
    j_count += q.select{|j| j.args.first.eql? self.id.to_s}.count
    j_count += 1 if b.map{|p| p.to_s.include?("ExtractAndUpdateReportWorker") and p.to_s.include?(self.id.to_s)}.include? true

    set report_complete: true if j_count.zero? and !compliance_report.empty?
    report_complete
  end

  def format_email
    self.email = email.downcase
  end

  def share_sheet
    GoogleDriveClient.add_permission report_sheet_id, email, 'reader' if email and report_sheet_id
  end
end
