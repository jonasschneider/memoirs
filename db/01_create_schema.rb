DB.create_table :memoirs do
  primary_key :id
  String :body
  String :editor
  Time :created_at # i actually rely on this being unique as well
end
