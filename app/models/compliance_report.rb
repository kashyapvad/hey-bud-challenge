class ComplianceReport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :plan, type: :string
  field :governance_body, type: :string
  field :complete, type: :boolean, default: false

  embeds_many :sections, class_name: "ComplianceReportSection"

  validates :governance_body, presence: true
end
