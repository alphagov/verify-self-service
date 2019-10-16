FactoryBot.define do
  factory :team do
    name { 'Team ' + SecureRandom.alphanumeric }
    team_alias { 'team' + SecureRandom.alphanumeric }
  end
end
