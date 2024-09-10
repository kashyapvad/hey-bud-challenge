class GovernaningBody
  include Mongoid::Document
  include Mongoid::Timestamps

  REQUIRED_FILES = {
    extraction_guide: nil,
    compliance_rules: {
    },
    report_templates: {

    },
  }

  field :files, type: :hash, default: REQUIRED_FILES
  field :prompt, type: :string

  has_many :compliance_reports
end