class Plan
  include Mongoid::Document
  include Mongoid::Timestamps

  field :file, type: :string
  #field :thread, type: :string #can be used to remmeber the context and enhance the report accuracy
  field :report_complete, type: :boolean, default: false
  field :compliance_report, type: :hash

  belongs_to :governing_body, index: true

  validates :governance_body, presence: true

  after_save :check_if_report_is_complete?  if: -> { compliance_report_changed? }


  def generate_report
    return unless plan
    ComplianceReportService.generate_report self
  end
  
  def update_report parameters
    return unless parameters
    r = self.report || {}
    r[:parameters] ||= []
    r[:parameters] += parameters
    plan.set report: r
  end

  def check_if_report_is_complete?
    parameters_check = {}
    governance_body.parameters.each{ |p| parameters_check[p.downcase.to_key.to_sym] = false }
    compliance_report.each do |key, val|
      if key.to_sym.eql? :parameters
        val.each do |v|
          vs = v.with_indifferent_access
          parameter = vs[:description].downcase.to_key.to_sym
          next unless parameters_check.keys.map(&:to_sym).include? parameter
          parameters_check[parameter] = true
        end
      end
    end
    set report_complete: true if !parameters_check.values.include? false
    report_complete
  end
end
