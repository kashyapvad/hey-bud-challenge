class ComplianceReport
  include Mongoid::Document
  include Mongoid::Timestamps


  REQUIRED_FILES = {
    extraction_guide: nil,
    compliance_rules: {
    },
    report_templates: {

    },
  }

  field :plan, type: :string
  field :files, type: :hash, default: REQUIRED_FILES
  field :prompt, type: :string
  field :governance_body, type: :string
  field :complete, type: :boolean, default: false

  embeds_many :sections, class_name: "ComplianceReportSection"

  validates :governance_body, presence: true
end
