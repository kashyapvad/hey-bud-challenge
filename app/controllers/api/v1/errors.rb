module Api::V1::Errors
  class CustomError < StandardError
  end

  class NoResultsFoundError < StandardError
  end
end
