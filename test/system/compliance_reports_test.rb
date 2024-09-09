require "application_system_test_case"

class ComplianceReportsTest < ApplicationSystemTestCase
  setup do
    @compliance_report = compliance_reports(:one)
  end

  test "visiting the index" do
    visit compliance_reports_url
    assert_selector "h1", text: "Compliance reports"
  end

  test "should create compliance report" do
    visit compliance_reports_url
    click_on "New compliance report"

    click_on "Create Compliance report"

    assert_text "Compliance report was successfully created"
    click_on "Back"
  end

  test "should update Compliance report" do
    visit compliance_report_url(@compliance_report)
    click_on "Edit this compliance report", match: :first

    click_on "Update Compliance report"

    assert_text "Compliance report was successfully updated"
    click_on "Back"
  end

  test "should destroy Compliance report" do
    visit compliance_report_url(@compliance_report)
    click_on "Destroy this compliance report", match: :first

    assert_text "Compliance report was successfully destroyed"
  end
end
