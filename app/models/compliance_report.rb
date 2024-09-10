class ComplianceReport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :plan, type: :string
  field :complete, type: :boolean, default: false

  belongs_to :governaning_body, index: true
  embeds_many :sections, class_name: "ComplianceReportSection"

  validates :governance_body, presence: true
end
