FactoryBot.define do
  factory :team do
    name { 'Team ' + SecureRandom.alphanumeric }
    team_alias { 'testteam' }
  end
end
