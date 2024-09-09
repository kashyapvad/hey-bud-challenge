class ComplianceReportSection
  include Mongoid::Document
  include Mongoid::Timestamps

  field :complete, type: :boolean, default: false
  field :report, type: :hash

  embedded_in :compliance_report

end