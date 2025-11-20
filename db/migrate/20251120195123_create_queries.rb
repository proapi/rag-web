class CreateQueries < ActiveRecord::Migration[8.1]
  def change
    create_table :queries do |t|
      t.references :user, null: false, foreign_key: true
      t.text :question
      t.text :answer
      t.json :metadata
      t.text :error

      t.timestamps
    end
  end
end
