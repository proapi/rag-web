FactoryBot.define do
  factory :query do
    association :user
    question { "What is the capital of France?" }
    answer { "The capital of France is Paris." }
    metadata { { "sources" => false, "top_k" => 1 } }
    error { nil }

    trait :failed do
      answer { nil }
      error { "Unable to reach RAG service" }
    end

    trait :successful do
      answer { "This is a successful answer." }
      error { nil }
    end
  end
end
