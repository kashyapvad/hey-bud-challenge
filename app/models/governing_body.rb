class GoverningBody
  include Mongoid::Document
  include Mongoid::Timestamps

  REQUIRED_FILES = {
    extraction_guide: [],
    compliance_rules: [],
  }

  field :name, type: :string
  field :assistant, type: :string
  field :parameters, type: :array
  #field :vector_store, type: :string
  #field :files, type: :hash, default: REQUIRED_FILES
  #field :prompt, type: :string

  has_many :plans
end