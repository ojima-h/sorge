Sequel.migration do
  change do
    create_table(:event_queue) do
      primary_key :id
      String :name, null: false
      String :data
      Integer :status
      Time :created_at
      Time :updated_at

      index [:status, :created_at]
      index [:status, :updated_at]
    end
  end
end
