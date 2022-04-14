# frozen_string_literal: true
# == Schema Information
#
# Table name: clients
#
#  id           :integer          not null, primary key
#  company_id   :integer          not null
#  name         :string           not null
#  email        :string
#  phone        :string
#  address      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  discarded_at :datetime
#  client_code  :string           not null
#
# Indexes
#
#  index_clients_on_client_code_and_company_id  (client_code,company_id) UNIQUE
#  index_clients_on_company_id                  (company_id)
#  index_clients_on_discarded_at                (discarded_at)
#  index_clients_on_email_and_company_id        (email,company_id) UNIQUE
#

# frozen_string_literal: true

class Client < ApplicationRecord
  include Discard::Model

  has_many :projects
  has_many :timesheet_entries, through: :projects
  has_many :invoices, dependent: :destroy
  belongs_to :company

  validates :name, :email, presence: true
  validates :client_code, presence: true, uniqueness: { scope: :company_id }
  validates :email, uniqueness: { scope: :company_id }, format: { with: Devise.email_regexp }
  after_discard :discard_projects

  def new_line_item_entries(selected_entries)
    timesheet_entries.where(bill_status: :unbilled)
      .joins(
        "INNER JOIN project_members ON timesheet_entries.project_id = project_members.project_id
          AND timesheet_entries.user_id = project_members.user_id"
      )
      .joins("INNER JOIN users ON project_members.user_id = users.id")
      .select(
        "timesheet_entries.id as id,
         users.first_name as first_name,
         users.last_name as last_name,
         timesheet_entries.work_date as date,
         timesheet_entries.note as description,
         project_members.hourly_rate as rate,
         timesheet_entries.duration as qty"
      ).where.not(id: selected_entries)
  end

  def total_hours_logged(time_frame = "week")
    from, to = week_month_year(time_frame)
    (projects.kept.map { |project| project.timesheet_entries.where(work_date: from..to).sum(:duration) }).sum
  end

  def project_details(time_frame = "week")
    from, to = week_month_year(time_frame)
    projects.kept.map do | project |
      {
        name: project.name, team: project.project_member_full_names,
        minutes_spent: project.timesheet_entries.where(work_date: from..to).sum(:duration)
      }
    end
  end

  def week_month_year(time_frame)
    case time_frame
    when "last_week"
      return Date.today.last_week.beginning_of_week, Date.today.last_week.end_of_week
    when "month"
      return Date.today.beginning_of_month, Date.today.end_of_month
    when "year"
      return Date.today.beginning_of_year, Date.today.end_of_year
    else
      return Date.today.beginning_of_week, Date.today.end_of_week
    end
  end

  def client_detail(time_frame = "week")
    {
      id: id,
      name: name,
      email: email,
      minutes_spent: total_hours_logged(time_frame)
    }
  end

  private

    def discard_projects
      projects.discard_all
    end
end
