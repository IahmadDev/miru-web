# frozen_string_literal: true

require "rails_helper"

RSpec.describe "InternalApi::V1::Projects#index", type: :request do
  let(:company) { create(:company) }
  let(:user_1) { create(:user, current_workspace_id: company.id) }
  let(:user_2) { create(:user, current_workspace_id: company.id) }
  let(:client_1) { create(:client, company:) }
  let(:client_2) { create(:client, company:) }
  let(:project_1) { create(:project, client: client_1) }
  let(:project_2) { create(:project, client: client_2) }

  context "when the user is an admin" do
    before do
      create(:company_user, company:, user: user_1)
      create(:company_user, company:, user: user_2)
      user_1.add_role :admin, company
      sign_in user_1
      create(:project_member, user: user_1, project: project_1)
      create(:project_member, user: user_1, project: project_2)
      create(:project_member, user: user_2, project: project_1)
      create(:project_member, user: user_2, project: project_2)
      create_list(:timesheet_entry, 5, user: user_1, project: project_1)
      create_list(:timesheet_entry, 5, user: user_1, project: project_2)
      create_list(:timesheet_entry, 5, user: user_2, project: project_1)
      create_list(:timesheet_entry, 5, user: user_2, project: project_2)
    end

    context "when no filters are applied" do
      it "returns list of all projects" do
        user_id, client_id, billable, search = nil
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when Search with project name" do
      it "returns projects with project_names matching search" do
        user_id, client_id, billable = nil, search = project_1.name
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when Search with client name" do
      it "returns projects with client_name matching search" do
        user_id, client_id, billable = nil, search = client_1.name
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when billable filter is applied" do
      it "returns projects which are non billable" do
        client_id, search, user_id = nil, billable = false
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when team member filter is applied" do
      it "returns projects which have user_1 as it's team member" do
        client_id, search, billable = nil, user_id = [user_1.id]
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when client filter is applied" do
      it "returns projects which belongs to client_1" do
        search, billable, user_id = nil, client_id = [client_1.id]
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when all filters and search both are applied" do
      it "returns projects as per filters and search" do
        search = project_2.name, billable = false, user_id = [user_1.id], client_id = [client_2.id]
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end
  end

  context "when the user is an employee" do
    before do
      create(:company_user, company:, user: user_1)
      create(:company_user, company:, user: user_2)
      user_1.add_role :employee, company
      sign_in user_1
      create(:project_member, user: user_1, project: project_1)
      create(:project_member, user: user_1, project: project_2)
      create(:project_member, user: user_2, project: project_1)
      create(:project_member, user: user_2, project: project_2)
      create_list(:timesheet_entry, 5, user: user_1, project: project_1)
      create_list(:timesheet_entry, 5, user: user_1, project: project_2)
      create_list(:timesheet_entry, 5, user: user_2, project: project_1)
      create_list(:timesheet_entry, 5, user: user_2, project: project_2)
    end

    context "when no filters are applied" do
      it "returns list of all projects" do
        user_id, client_id, billable, search = nil
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when Search with project name" do
      it "returns projects with project_names matching search" do
        user_id, client_id, billable = nil, search = project_1.name
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when Search with client name" do
      it "returns projects with client_name matching search" do
        user_id, client_id, billable = nil, search = client_1.name
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when billable filter is applied" do
      it "returns projects which are non billable" do
        client_id, search, user_id = nil, billable = false
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when team member filter is applied" do
      it "returns projects which have user_1 as it's team member" do
        client_id, search, billable = nil, user_id = [user_1.id]
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when client filter is applied" do
      it "returns projects which belongs to client_1" do
        search, billable, user_id = nil, client_id = [client_1.id]
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end

    context "when all filters and search both are applied" do
      it "returns projects as per filters and search" do
        search = project_2.name, billable = false, user_id = [user_1.id], client_id = [client_2.id]
        send_request :get, internal_api_v1_projects_path(params: { client_id:, user_id:, billable:, search: })
        projects = user_1.current_workspace.project_list(client_id, user_id, billable, search)
        expect(response).to have_http_status(:ok)
        expect(json_response["projects"]).to eq(JSON.parse(projects.to_json))
      end
    end
  end

  context "when unauthenticated" do
    it "is not permitted to view project" do
      send_request :get, internal_api_v1_projects_path
      expect(response).to have_http_status(:unauthorized)
      expect(json_response["error"]).to eq("You need to sign in or sign up before continuing.")
    end
  end
end