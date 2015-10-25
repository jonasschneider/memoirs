DB.alter_table :memoirs do
  add_column :embargoed_until, Date
end
