# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    company
    name { Faker::Name.name }
    email { Faker::Internet.unique.safe_email }
    phone { Faker::PhoneNumber.phone_number_with_country_code }
    address { Faker::Address.street_address }
    factory :client_with_invoices do
      transient do
        length { 5 }
      end
      invoices { Array.new(length) { create(:invoice, company:) } }
    end
    factory :client_with_phone_number_without_country_code do
      phone { Faker::PhoneNumber.cell_phone_in_e164 }
    end
  end
end
