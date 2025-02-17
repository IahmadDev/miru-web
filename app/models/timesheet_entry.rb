# frozen_string_literal: true

# == Schema Information
#
# Table name: timesheet_entries
#
#  id          :bigint           not null, primary key
#  bill_status :integer          not null
#  duration    :float            not null
#  note        :text             default("")
#  work_date   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_timesheet_entries_on_bill_status  (bill_status)
#  index_timesheet_entries_on_project_id   (project_id)
#  index_timesheet_entries_on_user_id      (user_id)
#  index_timesheet_entries_on_work_date    (work_date)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#

class TimesheetEntry < ApplicationRecord
  enum bill_status: [:non_billable, :unbilled, :billed]

  belongs_to :user
  belongs_to :project

  has_one :invoice_line_item, dependent: :destroy
  has_one :client, through: :project

  before_validation :ensure_bill_status_is_set
  before_validation :ensure_bill_status_is_not_billed, on: :create
  before_validation :ensure_billed_status_should_not_be_changed, on: :update

  validates :duration, :work_date, :bill_status, presence: true
  validates :duration, numericality: { less_than_or_equal_to: 6000000, greater_than_or_equal_to: 0.0 }

  scope :in_workspace, -> (company) { where(project_id: company&.project_ids) }
  scope :during, -> (from, to) { where(work_date: from..to).order(work_date: :desc) }

  delegate :name, to: :project, prefix: true, allow_nil: true
  delegate :name, to: :client, prefix: true, allow_nil: true
  delegate :full_name, to: :user, prefix: true, allow_nil: true

  scope :search_import, -> { includes(:project, :client, :user) }

  searchkick filterable: [:user_name, :created_at, :project_name, :client_name, :bill_status ],
    word_middle: [:user_name, :note]

  def search_data
    {
      id: id.to_i,
      project_id:,
      client_id: self.project&.client_id,
      user_id:,
      work_date: work_date.to_time,
      note:,
      user_name: user.full_name,
      project_name: project.name,
      client_name: project.client.name,
      bill_status:,
      duration: duration.to_i,
      created_at: created_at.to_time
    }
  end

  def snippet
    {
      id:,
      project: project.name,
      project_id:,
      client: project.client.name,
      duration:,
      note:,
      work_date:,
      bill_status:,
      team_member: user.full_name
    }
  end

  def formatted_duration
    minutes = duration.to_i
    Time.parse("#{minutes / 60}:#{minutes % 60}").strftime("%H:%M")
  end

  private

    def ensure_bill_status_is_set
      return if bill_status.present? || project.nil?

      if project.billable
        self.bill_status = :unbilled
      else
        self.bill_status = :non_billable
      end
    end

    def ensure_bill_status_is_not_billed
      errors.add(:timesheet_entry, I18n.t(:errors)[:create_billed_entry]) if billed?
    end

    def ensure_billed_status_should_not_be_changed
      return if Current.user.nil?

      errors.add(:timesheet_entry, I18n.t(:errors)[:bill_status_billed]) if
      self.bill_status_changed? && self.bill_status_was == "billed" && Current.user.primary_role(Current.company) == "employee"
    end
end
