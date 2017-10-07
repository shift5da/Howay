class CreateTagGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_groups do |t|
      t.string :name
      t.integer :seq
    end
    add_reference :tags, :tag_group, foreign_key: true
  end
end
