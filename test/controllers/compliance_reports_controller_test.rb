require "test_helper"

class ComplianceReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @compliance_report = compliance_reports(:one)
  end

  test "should get index" do
    get compliance_reports_url
    assert_response :success
  end

  test "should get new" do
    get new_compliance_report_url
    assert_response :success
  end

  test "should create compliance_report" do
    assert_difference("ComplianceReport.count") do
      post compliance_reports_url, params: { compliance_report: {  } }
    end

    assert_redirected_to compliance_report_url(ComplianceReport.last)
  end

  test "should show compliance_report" do
    get compliance_report_url(@compliance_report)
    assert_response :success
  end

  test "should get edit" do
    get edit_compliance_report_url(@compliance_report)
    assert_response :success
  end

  test "should update compliance_report" do
    patch compliance_report_url(@compliance_report), params: { compliance_report: {  } }
    assert_redirected_to compliance_report_url(@compliance_report)
  end

  test "should destroy compliance_report" do
    assert_difference("ComplianceReport.count", -1) do
      delete compliance_report_url(@compliance_report)
    end

    assert_redirected_to compliance_reports_url
  end
end
