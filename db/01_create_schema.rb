DB.create_table :memoirs do
  primary_key :id
  String :body
  String :editor
  Time :created_at
end
